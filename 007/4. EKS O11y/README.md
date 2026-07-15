
### 1) eks까지 먼저 apply

```bash
terraform init
terraform apply -target=module.vpc -target=module.ecr -target=module.eks --auto-approve
```

### 2) 컨테이너 이미지 빌드 & ECR push


```bash
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export REGION=ap-northeast-1
export REPO=$(aws ecr describe-repositories --repository-names o11y-app --region $REGION --query 'repositories[0].repositoryUri' --output text)

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

docker build -t o11y-app .
docker tag o11y-app:latest ${REPO}:latest
docker push ${REPO}:latest
```

### 3) main.tf, output.tf에서 전체 주석 해제 후 apply

```bash
terraform apply --auto-approve
```

lb_controller → app(ALB/TG/TargetGroupBinding) → loki → otel → grafana 순으로 생성된다.

## 검증

```bash
aws eks update-kubeconfig --region ap-northeast-1 --name o11y-cluster

# 로그 발생
APP_ALB=$(terraform output -raw app_alb_dns_name)
curl "http://$APP_ALB/log?level=info&count=20"

# Grafana 접속 (skills104 / GoodJob!Skills104^^)
terraform output -raw grafana_alb_dns_name
```

Grafana → Dashboards → **Log Overview** 에서 로그 건수/레벨분포/최근로그 확인.

## 참고
- TG 이름을 정확히(`o11y-app-tg`, `o11y-grafana-tg`) 맞추기 위해 Ingress 대신
  `aws_lb` + `aws_lb_target_group` + `TargetGroupBinding` 조합을 사용한다.
- `TargetGroupBinding`(CRD)은 plan 시점 CRD 부재 문제를 피하려 `kubectl_manifest`로 적용한다.
