output "rds_endpoint" {
  value = module.rds.endpoint
}

output "rds_proxy_endpoint" {
  value = module.proxy.proxy_endpoint
}

output "lambda_function_name" {
  value = module.lambda.function_name
}
