# CloudWatch 모듈 (Challenge 3)

FastAPI 앱 프로세스 수를 모니터링하는 CloudWatch 알람을 생성한다.

---

## 생성 리소스

| 리소스 | 이름 | 설명 |
|--------|------|------|
| `aws_cloudwatch_metric_alarm` | `gj2026-event-app-alarm` | 앱 프로세스 수 < 1 시 ALARM |

### 알람 설정

| 항목 | 값 |
|------|----|
| 네임스페이스 | `CWAgent` |
| 메트릭 | `app_process_count` |
| 통계 | Minimum |
| 기간 | 10초 |
| 조건 | `< 1` |
| 평가 기간 | 3회 중 1회 |
| 누락 데이터 처리 | ignore |

> `app_process_count` 메트릭은 EC2의 CWAgent가 전송함  
> CWAgent 미설치 또는 앱 미실행 시 메트릭이 없어 알람이 동작하지 않음

## Outputs

| 이름 | 설명 |
|------|------|
| `alarm_name` | 알람 이름 (EventBridge에서 참조) |
| `alarm_arn` | 알람 ARN |
