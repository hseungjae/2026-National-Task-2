output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}

output "lambda_function_name" {
  value = module.lambda.function_name
}

output "api_endpoint" {
  value = module.apigateway.api_endpoint
}
