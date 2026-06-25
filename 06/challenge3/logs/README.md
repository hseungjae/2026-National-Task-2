# Logs 모듈 (Challenge 3)

CloudWatch Logs 구독 필터를 통해 앱 기동 완료 로그를 감지하고 updater Lambda를 호출한다.

---

## 생성 리소스

| 리소스 | 이름 | 설명 |
|--------|------|------|
| `aws_cloudwatch_log_group` | `/gj2026/event/app-logs` | FastAPI 앱 로그 그룹 (7일 보관) |
| `aws_cloudwatch_log_group` | `/gj2026/event/recovery` | 복구 이벤트 로그 그룹 (7일 보관) |
| `aws_cloudwatch_log_subscription_filter` | `gj2026-startup-filter` | 기동 완료 로그 → updater Lambda |
| `aws_lambda_permission` | - | CloudWatch Logs → Lambda 호출 허용 |

### 구독 필터

- **로그 그룹**: `/gj2026/event/app-logs`
- **필터 패턴**: `Application startup complete`
- **대상**: updater Lambda

FastAPI 앱이 정상 기동되면 해당 문자열이 로그에 출력되고, updater Lambda가 자동 호출됨.

---

## Variables

| 이름 | 필수 | 설명 |
|------|------|------|
| `updater_lambda_arn` | Y | updater Lambda ARN |
| `updater_function_name` | Y | updater Lambda 이름 |
