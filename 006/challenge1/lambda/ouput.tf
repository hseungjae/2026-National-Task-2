output "rotate_function_url" {
  value = aws_lambda_function_url.rotate.function_url
}

output "rotate_function_name" {
  value = aws_lambda_function.rotate.function_name
}

output "request_qualified_arn" {
  value = aws_lambda_function.request.qualified_arn
}

output "response_qualified_arn" {
  value = aws_lambda_function.response.qualified_arn
}
