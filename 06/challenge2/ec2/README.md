# EC2 모듈 (Challenge 2)

Kafka가 설치·실행되는 EC2 인스턴스를 생성한다.

---

## 생성 리소스

| 리소스 | 이름 | 설명 |
|--------|------|------|
| `aws_instance` | `gj2026-data-ec2` | Kafka 서버 (t3.medium, AL2023) |
| `aws_security_group` | `gj2026-data-sg` | 22, 9092, 9094, 8081 inbound 허용 |
| `aws_key_pair` | `gj2026-data-key` | SSH Key Pair (자동 생성) |
| `local_file` | `gj2026-data-key.pem` | 모듈 경로에 PEM 저장 |
| `aws_iam_role` | `gj2026-data-ec2-role` | EC2 IAM Role (AdministratorAccess) |
| `aws_iam_instance_profile` | `gj2026-data-ec2-profile` | EC2 Instance Profile |

### 보안 그룹 인바운드 규칙

| 포트 | 용도 |
|------|------|
| 22 | SSH |
| 9092 | Kafka 내부 통신 |
| 9094 | Kafka 외부 접속 (NLB 경유) |
| 8081 | Flink Web UI |

---

## userdata 자동 처리

EC2 기동 시 S3에서 `setup_kafka.sh`, `app.py`를 다운로드하여 Kafka를 설치·실행한다.

### SSH 접속 및 로그 확인

```bash
ssh -i ec2/gj2026-data-key.pem ec2-user@<EC2_PUBLIC_IP>
sudo tail -f /var/log/userdata.log
```

---

## Variables

| 이름 | 필수 | 설명 |
|------|------|------|
| `vpc_id` | Y | VPC ID |
| `subnet_id` | Y | Subnet ID |
| `ami_id` | Y | Amazon Linux 2023 AMI ID |
| `instance_type` | N (기본: `t3.medium`) | EC2 타입 |
| `scripts_bucket` | Y | 설치 스크립트가 있는 S3 버킷 이름 |

## Outputs

| 이름 | 설명 |
|------|------|
| `kafka_instance_id` | EC2 인스턴스 ID |
| `kafka_private_ip` | EC2 프라이빗 IP |
