# Challenge 4 - Event-driven Pod Scaling with AWS SQS

## 리전
`us-west-2`

## 배포 순서

### 1단계 - 클러스터 생성 (helm 주석 처리 상태로 apply)

main.tf에서 `module "helm"` 블록 주석 처리 후:

```bash
terraform init
terraform apply
```

### 2단계 - helm repo 등록

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
```

### 3단계 - helm 설치 (주석 해제 후 apply)

main.tf에서 `module "helm"` 블록 주석 해제 후:

```bash
terraform apply
```

### 4단계 - Docker 이미지 빌드 & ECR 업로드

CloudShell에서 `script/push.sh` 업로드 후:

```bash
bash push.sh
```

### 5단계 - K8s 리소스 배포

CloudShell에서 `script/deploy.sh` 업로드 후:

```bash
bash deploy.sh
```

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
