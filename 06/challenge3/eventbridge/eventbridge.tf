resource "aws_cloudwatch_event_rule" "app_alarm" {
  name           = "gj2026-event-alarm-rule"
  description    = "Trigger recovery Lambda when app alarm fires"
  event_bus_name = "default"

  event_pattern = jsonencode({
    source        = ["aws.cloudwatch"]
    "detail-type" = ["CloudWatch Alarm State Change"]
    detail = {
      alarmName = [var.alarm_name]
      state = {
        value = ["ALARM"]
      }
    }
  })

  tags = { Name = "gj2026-event-alarm-rule" }
}

resource "aws_cloudwatch_event_target" "recovery_lambda" {
  rule           = aws_cloudwatch_event_rule.app_alarm.name
  event_bus_name = "default"
  target_id      = "gj2026-event-recovery-fn"
  arn            = var.lambda_arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.app_alarm.arn
}
