# Challenge 3 - Cloud Event Handling (자동 복구)

FastAPI 앱이 동작하는 EC2를 CloudWatch로 모니터링하고,  
앱 프로세스 다운 시 EventBridge → Lambda로 자동 복구하는 이벤트 드리븐 아키텍처.

---

## 수동 작업

### 1. Terraform 배포

```bash
cd challenge3
terraform init
terraform apply -auto-approve
```

### 2. EC2 SSH 접속 및 앱 상태 확인

```bash
ssh -i ec2/gj2026-event-key.pem ec2-user@<EC2_PUBLIC_IP>
sudo tail -f /var/log/userdata.log
```

### 3. Flink Studio에 AWS 지원 Kafka Connector 추가

Flink에서 Kafka를 사용하려면 AWS에서 지원하는 Kafka Connector를 Flink Studio 앱에 추가해야 한다.  
(Custom Connector가 아닌 AWS 지원 Connector 사용)

```
AWS 콘솔 → Managed Service for Apache Flink
→ gj2026-data-flink → Configure → Connectors
→ Add connector → Apache Kafka 선택
→ Save changes
```

---

### 4. Zeppelin 노트북 Query 실행

Connector 추가 후 Flink Studio 콘솔에서 **Open in Apache Zeppelin** 클릭 후 쿼리를 실행한다.

---

### 5. CloudWatch Agent 설치 확인

EC2 userdata에서 CWAgent가 `app_process_count` 커스텀 메트릭을 전송해야 알람이 동작함.

```bash
sudo systemctl status amazon-cloudwatch-agent
```

---

## 모듈 구성 및 동작 흐름

```
EC2 (FastAPI) → CWAgent → CloudWatch 알람
                                  ↓ (ALARM 상태)
                           EventBridge Rule
                                  ↓
                        recovery Lambda (SSM으로 앱 재시작)

EC2 (FastAPI) → CloudWatch Logs → Logs Subscription Filter
                                  ↓ ("Application startup complete" 감지)
                        updater Lambda (SSM Parameter 업데이트)
```

| 모듈 | 경로 | 역할 |
|------|------|------|
| iam | `./iam` | EC2, recovery Lambda, updater Lambda Role 생성 |
| ec2 | `./ec2` | FastAPI EC2 인스턴스 생성 |
| cloudwatch | `./cloudwatch` | 앱 프로세스 수 모니터링 알람 생성 |
| lambda | `./lambda` | recovery / updater Lambda 생성 |
| eventbridge | `./eventbridge` | 알람 → recovery Lambda 연결 |
| logs | `./logs` | 로그 구독 필터 → updater Lambda 연결 |

---

## Variables

| 이름 | 기본값 | 설명 |
|------|--------|------|
| `instance_type` | `t3.small` | EC2 인스턴스 타입 |
| `key_name` | `""` | Key Pair (미사용, 모듈 내부 생성) |
