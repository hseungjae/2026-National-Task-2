# Challenge 2 - 수동 작업 가이드

## 1. Terraform Apply

```bash
cd terraform/2026-National-Task-2/05/challenge2
terraform init
terraform apply -auto-approve
```

생성되는 리소스:
- Hub VPC + Spoke VPC (VPC Peering)
- Bastion EC2 (Hub), App EC2 v1/v2 (Spoke)
- ALB (Spoke 내부)
- VPC Lattice (Service Network, Service, Listener, Target Group)

---

## 2. 수동 작업 없음

Challenge 2는 Terraform만으로 모든 리소스가 구성됩니다.

---

## 3. 확인 명령어

```bash
# VPC Lattice 서비스 URL 확인
aws vpc-lattice list-services --query "items[*].dnsEntry.domainName"

# Bastion에서 VPC Lattice 엔드포인트 접속 테스트
# (Bastion EC2에 SSH 접속 후)
curl http://<LATTICE_SERVICE_DNS>/
curl -H "version: v1" http://<LATTICE_SERVICE_DNS>/
curl -H "version: v2" http://<LATTICE_SERVICE_DNS>/
```
