# Challenge 1 - DocumentDB based NoSQL Application

## 리전
`ap-northeast-2`

## 배포 순서

```bash
terraform init
terraform apply
```

## 확인
```bash
export NOSQL_CLIENT_EC2_PUBLIC_IP=$(aws ec2 describe-instances \
  --region ap-northeast-2 \
  --filters Name=tag:Name,Values=skills-nosql-client-ec2 Name=instance-state-name,Values=running \
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

curl -s -w "\nhttp_code=%{http_code}\n" http://${NOSQL_CLIENT_EC2_PUBLIC_IP}:8080/health
curl -s -w "\nhttp_code=%{http_code}\n" http://${NOSQL_CLIENT_EC2_PUBLIC_IP}:8080/v1/admin/summary
```
