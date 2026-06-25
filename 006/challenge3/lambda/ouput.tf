output "recovery_function_arn" {
  value = aws_lambda_function.recovery.arn
}

output "recovery_function_name" {
  value = aws_lambda_function.recovery.function_name
}

output "updater_function_arn" {
  value = aws_lambda_function.updater.arn
}

output "updater_function_name" {
  value = aws_lambda_function.updater.function_name
}
