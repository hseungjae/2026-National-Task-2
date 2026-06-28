module "dynamodb" {
  source = "./dynamodb"
  prefix = var.prefix
}

module "lambda" {
  source             = "./lambda"
  prefix             = var.prefix
  dynamodb_table_arn = module.dynamodb.table_arn
}

module "api_gateway" {
  source               = "./api_gateway"
  prefix               = var.prefix
  lambda_invoke_arn    = module.lambda.lambda_invoke_arn
  lambda_function_name = module.lambda.lambda_function_name
}
