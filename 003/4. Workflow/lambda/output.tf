output "validator_arn" {
  value = aws_lambda_function.validator.arn
}

output "payment_arn" {
  value = aws_lambda_function.payment.arn
}

output "validator_name" {
  value = aws_lambda_function.validator.function_name
}

output "payment_name" {
  value = aws_lambda_function.payment.function_name
}
