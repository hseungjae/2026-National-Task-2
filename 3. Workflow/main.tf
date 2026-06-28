module "s3" {
  source = "./s3"
  prefix = var.prefix
}

module "dynamodb" {
  source = "./dynamodb"
}

module "lambda" {
  source             = "./lambda"
  s3_bucket_arn      = module.s3.bucket_arn
  dynamodb_table_arn = module.dynamodb.table_arn
}

module "step_functions" {
  source               = "./step_functions"
  lambda_function_name = module.lambda.function_name
}