resource "aws_cloudwatch_metric_alarm" "app" {
  alarm_name          = "gj2026-event-app-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 1
  metric_name         = "app_process_count"
  namespace           = "CWAgent"
  period              = 10
  statistic           = "Minimum"
  threshold           = 1
  treat_missing_data  = "ignore"
  alarm_description   = "Alarm when app process count is less than 1"

  tags = { Name = "gj2026-event-app-alarm" }
}
