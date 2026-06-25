#!/bin/bash
set -e

CLUSTER_NAME="skills-sqs-cluster"
REGION="us-west-2"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

SQS_QUEUE_URL=$(aws sqs get-queue-url --queue-name skills-sqs-queue --region $REGION --query QueueUrl --output text)
ECR_REPO_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/skills-sqs-ecr"
WORKER_ROLE_ARN=$(aws iam get-role --role-name skills-sqs-worker-role --query Role.Arn --output text)
NODE_ROLE_NAME=$(aws iam get-role --role-name skills-sqs-node-role --query Role.RoleName --output text)

echo "Cluster:     $CLUSTER_NAME"
echo "Region:      $REGION"
echo "Account:     $ACCOUNT_ID"
echo "SQS URL:     $SQS_QUEUE_URL"
echo "ECR URL:     $ECR_REPO_URL"
echo "Worker Role: $WORKER_ROLE_ARN"
echo "Node Role:   $NODE_ROLE_NAME"

echo "=== Configuring kubectl ==="
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"

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
