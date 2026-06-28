output "score_function_arn" {
  value = aws_lambda_function.score_function.arn
}

output "score_function_name" {
  value = aws_lambda_function.score_function.function_name
}

output "trigger_function_arn" {
  value = aws_lambda_function.trigger_function.arn
}

output "trigger_function_name" {
  value = aws_lambda_function.trigger_function.function_name
}
