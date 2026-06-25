# ── Module 3: Workflow (us-east-1) ───────────────────────────────────────────
# S3/DynamoDB → IAM → Lambda → StepFunctions → EventBridge

module "s3" {
  source      = "./s3"
  bucket_name = var.bucket_name
}

module "dynamodb" {
  source     = "./dynamodb"
  table_name = var.table_name
}

module "iam" {
  source                  = "./iam"
  account_id              = data.aws_caller_identity.current.account_id
  region                  = data.aws_region.current.region
  bucket_arn              = module.s3.bucket_arn
  table_arn               = module.dynamodb.table_arn
  transform_function_name = var.transform_function_name
}

module "lambda" {
  source        = "./lambda"
  function_name = var.transform_function_name
  role_arn      = module.iam.workflow_role_arn

  depends_on = [module.iam]
}

module "stepfunctions" {
  source             = "./stepfunctions"
  state_machine_name = var.state_machine_name
  role_arn           = module.iam.workflow_role_arn
  lambda_arn         = module.lambda.function_arn
}

module "eventbridge" {
  source            = "./eventbridge"
  rule_name         = var.rule_name
  bucket_name       = var.bucket_name
  state_machine_arn = module.stepfunctions.state_machine_arn
}
