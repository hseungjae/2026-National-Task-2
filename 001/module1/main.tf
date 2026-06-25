# ── Module 1: REST API Implement (ap-northeast-2) ────────────────────────────
# DynamoDB → IAM → Lambda → API Gateway 순으로 의존성 구성

module "dynamodb" {
  source     = "./dynamodb"
  table_name = var.table_name
}

module "iam" {
  source        = "./iam"
  function_name = var.function_name
  table_arn     = module.dynamodb.table_arn
}

module "lambda" {
  source        = "./lambda"
  function_name = var.function_name
  role_arn      = module.iam.role_arn

  depends_on = [module.iam]
}

module "apigateway" {
  source               = "./apigateway"
  api_name             = var.api_name
  stage_name           = var.stage_name
  region               = data.aws_region.current.region
  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name
}
