# Lambda 모듈 (Challenge 3)

앱 자동 복구(recovery)와 상태 업데이트(updater) Lambda 함수를 생성한다.

---

## 생성 리소스

| 리소스 | 이름 | 설명 |
|--------|------|------|
| `aws_lambda_function` | `gj2026-event-recovery` | 앱 프로세스 복구 Lambda |
| `aws_lambda_function` | `gj2026-event-updater` | 앱 기동 완료 후 상태 업데이트 Lambda |
| `aws_cloudwatch_log_group` | `/aws/lambda/gj2026-event-recovery` | recovery Lambda 로그 (7일 보관) |
| `aws_cloudwatch_log_group` | `/aws/lambda/gj2026-event-updater` | updater Lambda 로그 (7일 보관) |

### Lambda 설정

| 함수 | Runtime | Timeout | Memory | 트리거 |
|------|---------|---------|--------|--------|
| recovery | python3.12 | 120s | 256MB | EventBridge (알람 ALARM 시) |
| updater | python3.12 | 120s | 256MB | CloudWatch Logs 구독 필터 |

### 환경 변수

두 함수 모두 `INSTANCE_ID` 환경 변수로 EC2 인스턴스 ID를 받아 SSM SendCommand로 제어함.

---

## Variables

| 이름 | 필수 | 설명 |
|------|------|------|
| `recovery_role_arn` | Y | recovery Lambda 실행 Role ARN |
| `updater_role_arn` | Y | updater Lambda 실행 Role ARN |
| `instance_id` | Y | 제어 대상 EC2 인스턴스 ID |

## Outputs

| 이름 | 설명 |
|------|------|
| `recovery_function_arn` | recovery Lambda ARN |
| `recovery_function_name` | recovery Lambda 이름 |
| `updater_function_arn` | updater Lambda ARN |
| `updater_function_name` | updater Lambda 이름 |
