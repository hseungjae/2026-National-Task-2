#!/bin/bash
set -e

CLUSTER_NAME="skills-sqs-cluster"
REGION="us-west-2"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

SQS_QUEUE_URL=$(aws sqs get-queue-url --queue-name skills-sqs-queue --region $REGION --query QueueUrl --output text)
ECR_REPO_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/skills-sqs-ecr"
WORKER_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/skills-sqs-worker-role"
NODE_ROLE_NAME="skills-sqs-node-role"
KARPENTER_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/skills-sqs-karpenter-role"
KEDA_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/skills-sqs-keda-role"
EKS_CLUSTER_SG=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" \
  --query 'cluster.resourcesVpcConfig.clusterSecurityGroupId' --output text)

echo "Cluster:     $CLUSTER_NAME"
echo "Region:      $REGION"
echo "Account:     $ACCOUNT_ID"
echo "SQS URL:     $SQS_QUEUE_URL"
echo "ECR URL:     $ECR_REPO_URL"
echo "Worker Role: $WORKER_ROLE_ARN"
echo "Node Role:   $NODE_ROLE_NAME"

echo "=== Configuring kubectl ==="
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash


echo "=== CoreDNS Fargate 설정 ==="
kubectl patch deployment coredns -n kube-system --type=merge \
  -p='{"spec":{"template":{"metadata":{"annotations":{"eks.amazonaws.com/compute-type":null}}}}}' 2>/dev/null || true
kubectl rollout restart deployment/coredns -n kube-system
echo "CoreDNS Fargate 프로비저닝 대기 중..."
kubectl rollout status deployment/coredns -n kube-system --timeout=300s

echo "=== aws-logging ConfigMap 생성 ==="
kubectl create namespace aws-observability --dry-run=client -o yaml | kubectl apply -f -
kubectl create configmap aws-logging -n aws-observability \
  --from-literal=flb_log_cw=false --dry-run=client -o yaml | kubectl apply -f -

echo "=== Karpenter 설치 ==="
helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter \
  --version 1.3.3 \
  --namespace karpenter \
  --create-namespace \
  --set settings.clusterName="$CLUSTER_NAME" \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$KARPENTER_ROLE_ARN" \
  --wait --timeout 5m

echo "=== KEDA 설치 ==="
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm upgrade --install keda kedacore/keda \
  --namespace keda \
  --create-namespace \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$KEDA_ROLE_ARN" \
  --wait --timeout 5m

echo "=== Creating namespace ==="
kubectl create namespace skills-sqs --dry-run=client -o yaml | kubectl apply -f -

echo "=== Creating Service Account ==="
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sqs-worker-sa
  namespace: skills-sqs
  annotations:
    eks.amazonaws.com/role-arn: $WORKER_ROLE_ARN
EOF

echo "=== Creating EC2NodeClass ==="
kubectl apply -f - <<EOF
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: skills-sqs-nodeclass
spec:
  amiSelectorTerms:
    - alias: al2023@latest
  role: $NODE_ROLE_NAME
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: $CLUSTER_NAME
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: $CLUSTER_NAME
    - id: $EKS_CLUSTER_SG
  tags:
    karpenter.sh/discovery: $CLUSTER_NAME
EOF

echo "=== Creating NodePool ==="
kubectl apply -f - <<EOF
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: skills-sqs-nodepool
spec:
  template:
    metadata:
      labels:
        skills-nodepool: event-worker
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: skills-sqs-nodeclass
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["t3.small", "t3.medium"]
  limits:
    cpu: "10"
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 30s
EOF

echo "=== Creating Deployment ==="
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sqs-worker
  namespace: skills-sqs
spec:
  replicas: 0
  selector:
    matchLabels:
      app: sqs-worker
  template:
    metadata:
      labels:
        app: sqs-worker
    spec:
      serviceAccountName: sqs-worker-sa
      nodeSelector:
        karpenter.sh/nodepool: skills-sqs-nodepool
        skills-nodepool: event-worker
      containers:
        - name: worker
          image: $ECR_REPO_URL:latest
          env:
            - name: SQS_QUEUE_URL
              value: "$SQS_QUEUE_URL"
            - name: AWS_REGION
              value: "$REGION"
            - name: PROCESSING_SECONDS
              value: "5"
EOF

echo "=== Creating TriggerAuthentication ==="
kubectl apply -f - <<EOF
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: sqs-worker-trigger-auth
  namespace: skills-sqs
spec:
  podIdentity:
    provider: aws
EOF

echo "=== Creating ScaledObject ==="
kubectl apply -f - <<EOF
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: sqs-worker-scaledobject
  namespace: skills-sqs
spec:
  scaleTargetRef:
    name: sqs-worker
  minReplicaCount: 0
  maxReplicaCount: 6
  pollingInterval: 15
  cooldownPeriod: 30
  triggers:
    - type: aws-sqs-queue
      authenticationRef:
        name: sqs-worker-trigger-auth
      metadata:
        queueURL: $SQS_QUEUE_URL
        queueLength: "2"
        awsRegion: $REGION
        identityOwner: operator
EOF

echo "=== Done! ==="
echo "ECR Repository: $ECR_REPO_URL"
echo "SQS Queue URL:  $SQS_QUEUE_URL"
