#!/bin/bash
set -e

CLUSTER_NAME="wsc-scaling-cluster"
REGION="ap-northeast-2"
NODE_ROLE_NAME="AmazonEKSNodeRole"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
SQS_QUEUE_URL=$(aws sqs get-queue-url --queue-name wsc-scaling-sqs --region $REGION --query QueueUrl --output text)

aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

# Helm 설치 (미설치 시)
if ! command -v helm &>/dev/null; then
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Karpenter 설치
KARPENTER_VERSION="1.4.0"
KARPENTER_ROLE_ARN=$(aws iam get-role \
  --role-name KarpenterControllerRole \
  --query Role.Arn \
  --output text)

helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter \
  --version "$KARPENTER_VERSION" \
  --namespace kube-system \
  --set "settings.clusterName=$CLUSTER_NAME" \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$KARPENTER_ROLE_ARN" \
  --wait --timeout 5m

# KEDA 설치
KEDA_ROLE_ARN=$(aws iam get-role \
  --role-name KedaOperatorRole \
  --query Role.Arn \
  --output text)

helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm upgrade --install keda kedacore/keda \
  --namespace keda \
  --create-namespace \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$KEDA_ROLE_ARN" \
  --wait --timeout 5m

kubectl apply -f - <<EOF
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2023
  role: $NODE_ROLE_NAME
  subnetSelectorTerms:
  - tags:
      karpenter.sh/discovery: $CLUSTER_NAME
  securityGroupSelectorTerms:
  - tags:
      karpenter.sh/discovery: $CLUSTER_NAME
  amiSelectorTerms:
  - alias: al2023@latest
EOF

kubectl apply -f - <<EOF
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default
      requirements:
      - key: kubernetes.io/arch
        operator: In
        values: ["amd64"]
      - key: karpenter.sh/capacity-type
        operator: In
        values: ["on-demand"]
      - key: node.kubernetes.io/instance-type
        operator: In
        values: ["t3.medium", "t3.large", "t3.xlarge"]
  limits:
    cpu: 100
    memory: 200Gi
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 30s
EOF

kubectl apply -f - <<EOF
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: wsc-scaling-scaledobject
  namespace: wsc-scaling
spec:
  scaleTargetRef:
    name: wsc-scaling-deploy
  pollingInterval: 30
  cooldownPeriod: 30
  minReplicaCount: 2
  maxReplicaCount: 100
  triggers:
  - type: aws-sqs-queue
    metadata:
      queueURL: $SQS_QUEUE_URL
      queueLength: "5"
      awsRegion: $REGION
      identityOwner: operator
EOF

echo "Done!"
