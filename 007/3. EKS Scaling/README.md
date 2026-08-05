# Module 3 - EKS Scaling

## 1) VPC, ECR, EKS 먼저 apply

```bash
terraform init
terraform apply -target="module.vpc" -target="module.ecr" -target="module.eks" -auto-approve
```

## 2) 컨테이너 이미지 빌드 & ECR push

Dockerfile은 `docker/` 폴더에 있습니다. 그 안으로 이동한 뒤 실행하세요.

```bash
cd docker

export ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com

docker build -t skm-ecr .
docker tag skm-ecr:latest ${ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com/skm-ecr:latest
docker push ${ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com/skm-ecr:latest

cd ..
```

## 3) 나머지 전체 apply

```bash
terraform apply --auto-approve
```

karpenter → keda → k8s(ECR 이미지 사용) 순으로 생성됩니다.
