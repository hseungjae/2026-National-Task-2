# Challenge 3 - 수동 작업 가이드

## 1. Terraform Apply

```bash
cd terraform/2026-National-Task-2/05/challenge3
terraform init
terraform apply -auto-approve
```

완료 후 생성되는 리소스:
- VPC, 서브넷
- EKS 클러스터 (wsc-logging-cluster, v1.35)
- Node Group (wsc-logging-ng, min=2 max=4 desired=2)
- IAM Role (bastion, node, ebs-csi)
- Bastion EC2 (wsc-logging-app-bastion)
- Helm: Loki, Grafana (wsc-logging 네임스페이스)
- gp2 StorageClass default 패치

SSH 키 파일은 `ec2/wsc-logging-bastion-key.pem`에 저장됨.

---

## 2. Bastion 접속

```bash
# Bastion 퍼블릭 IP 확인
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=wsc-logging-app-bastion" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text

# SSH 접속
ssh -i terraform/2026-National-Task-2/05/challenge3/ec2/wsc-logging-bastion-key.pem \
    ec2-user@<BASTION_PUBLIC_IP>
```

---

## 3. apply-manifests.sh 스크립트 실행 (Bastion에서)

Bastion에 스크립트를 복사한 후 실행:

```bash
# 로컬에서 스크립트 복사
scp -i terraform/2026-National-Task-2/05/challenge3/ec2/wsc-logging-bastion-key.pem \
    terraform/2026-National-Task-2/05/challenge3/script/apply-manifests.sh \
    ec2-user@<BASTION_PUBLIC_IP>:~/apply-manifests.sh

# Bastion에서 실행
chmod +x ~/apply-manifests.sh
./apply-manifests.sh
```

스크립트가 처리하는 작업:
1. kubectl 설치
2. EKS kubeconfig 업데이트
3. gp2 StorageClass default 패치
4. Loki 서비스 → LoadBalancer(NLB) 패치
5. Loki NLB 주소 대기
6. Fluent Bit 설치
7. Docker 설치 및 Flask 앱 컨테이너 실행
8. Fluent Bit 설정 (`/etc/fluent-bit/fluent-bit.conf`, `parsers.conf`)
9. Fluent Bit 서비스 시작

---

## 4. 로그 생성 (Bastion에서)

Flask 앱이 실행된 후 로그 생성:

```bash
curl http://localhost:5000/generate?count=20
```

---

## 5. 확인 명령어

```bash
# Fluent Bit 상태
sudo systemctl status fluent-bit

# Fluent Bit 로그 (Loki 전송 확인)
sudo journalctl -u fluent-bit -f --no-pager

# Flask 앱 로그
sudo docker logs wsc-log-app

# Loki NLB 주소 확인
kubectl get svc loki -n wsc-logging

# Grafana NLB 주소 확인
kubectl get svc grafana -n wsc-logging

# 모든 Pod 상태
kubectl get pods -n wsc-logging
```

---

## 6. Grafana 접속

| 항목 | 값 |
|------|-----|
| URL | `http://<GRAFANA_NLB_ADDRESS>` |
| ID | `wsc2026-admin-<contestant_number>` |
| PW | `admin<contestant_number>!` |

대시보드: **WSC2026 Container Logs**

---

## 7. 재실행 시 주의사항

- Fluent Bit DB 파일 초기화 (중복 전송 방지):
  ```bash
  sudo rm -f /var/log/flb_docker.db
  sudo systemctl restart fluent-bit
  ```

- Helm 재설치 필요 시:
  ```bash
  helm uninstall grafana -n wsc-logging
  helm uninstall loki -n wsc-logging
  # 이후 terraform apply
  ```
