# EventBridge 모듈 (Challenge 3)

CloudWatch 알람 상태 변경 이벤트를 감지하여 recovery Lambda를 트리거하는 규칙을 생성한다.

---

## 생성 리소스

| 리소스 | 이름 | 설명 |
|--------|------|------|
| `aws_cloudwatch_event_rule` | `gj2026-event-alarm-rule` | CloudWatch 알람 ALARM 상태 감지 규칙 |
| `aws_cloudwatch_event_target` | - | recovery Lambda를 타겟으로 지정 |
| `aws_lambda_permission` | - | EventBridge → Lambda 호출 허용 |

### 이벤트 패턴

```json
{
  "source": ["aws.cloudwatch"],
  "detail-type": ["CloudWatch Alarm State Change"],
  "detail": {
    "alarmName": ["gj2026-event-app-alarm"],
    "state": { "value": ["ALARM"] }
  }
}
```

알람이 `ALARM` 상태가 될 때만 recovery Lambda 호출.

---

## Variables

| 이름 | 필수 | 설명 |
|------|------|------|
| `lambda_arn` | Y | recovery Lambda ARN |
| `lambda_function_name` | Y | recovery Lambda 이름 |
| `alarm_name` | Y | 감지할 CloudWatch 알람 이름 |
