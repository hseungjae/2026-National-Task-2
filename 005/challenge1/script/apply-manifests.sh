#!/bin/bash
set -e

CLUSTER_NAME="wsc-scaling-cluster"
REGION="ap-northeast-2"
NODE_ROLE_NAME="AmazonEKSNodeRole"
SQS_QUEUE_URL=$(aws sqs get-queue-url --queue-name wsc-scaling-sqs --region $REGION --query QueueUrl --output text)

aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

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
