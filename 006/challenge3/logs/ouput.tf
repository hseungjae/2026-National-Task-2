output "app_logs_group" {
  value = aws_cloudwatch_log_group.app_logs.name
}

output "recovery_logs_group" {
  value = aws_cloudwatch_log_group.recovery.name
}
