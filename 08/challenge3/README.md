# Challenge 3 - Cloud Event Handling

## 리전
`ap-southeast-1`

## 배포 순서

```bash
terraform init
terraform apply
```

## 확인
```bash
export PROTECTED_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
  --region ap-southeast-1 \
  --filters Name=tag:Name,Values=skills-ceh-protected-sg \
  --query "SecurityGroups[0].GroupId" --output text)

# Inbound 규칙 추가 → Lambda 자동 제거 테스트
aws ec2 authorize-security-group-ingress \
  --region ap-southeast-1 \
  --group-id "$PROTECTED_SECURITY_GROUP_ID" \
  --protocol tcp --port 22 --cidr 0.0.0.0/0

# 180초 내 규칙이 제거되는지 확인
aws ec2 describe-security-groups \
  --region ap-southeast-1 \
  --group-ids "$PROTECTED_SECURITY_GROUP_ID" \
  --query "SecurityGroups[0].IpPermissions" --output json
```
