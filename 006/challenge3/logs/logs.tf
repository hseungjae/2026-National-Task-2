resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/gj2026/event/app-logs"
  retention_in_days = 7

  tags = { Name = "gj2026-event-app-logs" }
}

resource "aws_cloudwatch_log_group" "recovery" {
  name              = "/gj2026/event/recovery"
  retention_in_days = 7

  tags = { Name = "gj2026-event-recovery" }
}

resource "aws_lambda_permission" "logs_invoke_updater" {
  statement_id  = "AllowCloudWatchLogsInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.updater_function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.app_logs.arn}:*"
}

resource "aws_cloudwatch_log_subscription_filter" "startup" {
  name            = "gj2026-startup-filter"
  log_group_name  = aws_cloudwatch_log_group.app_logs.name
  filter_pattern  = "Application startup complete"
  destination_arn = var.updater_lambda_arn

  depends_on = [aws_lambda_permission.logs_invoke_updater]
}
