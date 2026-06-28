# EC2 모듈 (Challenge 3)

FastAPI 앱이 실행되는 EC2 인스턴스를 생성한다.

---

## 생성 리소스

| 리소스 | 이름 | 설명 |
|--------|------|------|
| `aws_instance` | `gj2026-event-ec2` | FastAPI 앱 서버 (AL2023) |
| `aws_security_group` | `gj2026-event-sg` | 22, 8080 inbound 허용 |
| `aws_key_pair` | `gj2026-event-key` | SSH Key Pair (자동 생성) |
| `local_file` | `gj2026-event-key.pem` | 모듈 경로에 PEM 저장 |

### 보안 그룹 인바운드 규칙

| 포트 | 용도 |
|------|------|
| 22 | SSH |
| 8080 | FastAPI 앱 |

---

## userdata 자동 처리

- FastAPI 앱(`app.py`)을 base64로 내장하여 EC2 기동 시 디코딩·실행
- CWAgent 설치 및 `app_process_count` 커스텀 메트릭 전송 설정

### SSH 접속

```bash
ssh -i ec2/gj2026-event-key.pem ec2-user@<EC2_PUBLIC_IP>
sudo tail -f /var/log/userdata.log
```

---

## Variables

| 이름 | 필수 | 설명 |
|------|------|------|
| `vpc_id` | Y | VPC ID |
| `subnet_id` | Y | Subnet ID |
| `ami_id` | Y | Amazon Linux 2023 AMI ID |
| `instance_type` | N | EC2 타입 |
| `ec2_role_name` | Y | EC2 IAM Role 이름 |
| `ec2_profile_name` | Y | EC2 Instance Profile 이름 |

## Outputs

| 이름 | 설명 |
|------|------|
| `instance_id` | EC2 인스턴스 ID |
| `public_ip` | 공인 IP |
