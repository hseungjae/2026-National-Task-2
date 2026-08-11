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
chmod +x push.sh && ./push.sh
```

### 4단계 - K8s 리소스 배포

CloudShell에서 `script/deploy.sh` 업로드 후:

```bash
chmod +x deploy.sh && ./deploy.sh
```