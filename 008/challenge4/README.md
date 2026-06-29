# Challenge 4 - Event-driven Pod Scaling with AWS SQS

## 리전
`us-west-2`

## 배포 순서

### 1단계 - 클러스터 생성

```bash
terraform init
terraform apply
```

### 2단계 - kubectl 설정

```bash
aws eks update-kubeconfig --name skills-sqs-cluster --region us-west-2
```

### 3단계 - Docker 이미지 빌드 & ECR 업로드

CloudShell에서 `script/push.sh` 업로드 후:

```bash
sed -i 's/\r//' push.sh && chmod +x push.sh && ./push.sh
```

### 4단계 - K8s 리소스 배포

CloudShell에서 `script/deploy.sh` 업로드 후:

```bash
sed -i 's/\r//' deploy.sh && chmod +x deploy.sh && ./deploy.sh
```

스크립트가 자동으로 처리하는 항목:
- CoreDNS Fargate 스케줄링 설정 및 대기
- aws-logging ConfigMap 생성
- Karpenter 설치
- KEDA 설치
- K8s 리소스 배포 (EC2NodeClass, NodePool, Deployment, ScaledObject)

## 확인

```bash
# KEDA/Karpenter pod 상태
kubectl get pods -n keda -o wide
kubectl get pods -n karpenter -o wide

# Worker 리소스 확인
kubectl get deployment sqs-worker -n skills-sqs
kubectl get scaledobject sqs-worker-scaledobject -n skills-sqs
kubectl get triggerauthentication sqs-worker-trigger-auth -n skills-sqs

# Scale out 테스트 (메시지 12개 전송)
QUEUE_URL=$(aws sqs get-queue-url --region us-west-2 --queue-name skills-sqs-queue --query QueueUrl --output text)
for i in $(seq 1 12); do aws sqs send-message --region us-west-2 --queue-url "$QUEUE_URL" --message-body "judge-$i"; done
kubectl get pods -n skills-sqs -l app=sqs-worker -o wide
kubectl get nodes -l karpenter.sh/nodepool=skills-sqs-nodepool,skills-nodepool=event-worker -o wide
```

## CloudShell 접속 시 주의사항

- EKS Security Group이 `0.0.0.0/0` 허용으로 설정되어 있어야 함
- VPC 연결 없는 기본 CloudShell 모드에서 접속
- kubectl 미설치 시 채점 스크립트가 자동 설치함
