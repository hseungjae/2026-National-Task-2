module "dynamodb" {
  source = "./dynamodb"
}

module "iam" {
  source     = "./iam"
  region     = var.region
  account_id = data.aws_caller_identity.current.account_id
}

module "lambda" {
  source            = "./lambda"
  lambda_role_arn   = module.iam.lambda_role_arn
  table_name        = module.dynamodb.table_name
  region            = var.region
}

module "apigateway" {
  source              = "./apigateway"
  lambda_invoke_arn   = module.lambda.lambda_invoke_arn
  lambda_function_name = module.lambda.lambda_function_name
  region              = var.region
  account_id          = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}
