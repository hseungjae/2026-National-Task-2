# Challenge 2 - Simplify Service Networking with VPC Lattice

## 리전
`ap-northeast-1`

## 배포 순서

```bash
terraform init
terraform apply
```

## 확인
```bash
export LATTICE_CLIENT_EC2_PUBLIC_IP=$(aws ec2 describe-instances \
  --region ap-northeast-1 \
  --filters Name=tag:Name,Values=skills-lattice-client-ec2 Name=instance-state-name,Values=running \
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

curl -s -w "\nhttp_code=%{http_code}\n" http://${LATTICE_CLIENT_EC2_PUBLIC_IP}/health
curl -s -w "\nhttp_code=%{http_code}\n" "http://${LATTICE_CLIENT_EC2_PUBLIC_IP}/v1/client/orders?id=1001"
```
