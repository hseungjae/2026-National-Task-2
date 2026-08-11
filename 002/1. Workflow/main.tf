module "s3" {
  source            = "./s3"
  contestant_number = var.contestant_number
}

module "dynamodb" {
  source = "./dynamodb"
}

module "iam" {
  source        = "./iam"
  s3_bucket_arn = module.s3.bucket_arn
  dynamodb_arn  = module.dynamodb.table_arn
  account_id    = data.aws_caller_identity.current.account_id
  region        = var.region
}

module "lambda" {
  source                  = "./lambda"
  lambda_role_arn         = module.iam.lambda_role_arn
  lambda_trigger_role_arn = module.iam.lambda_trigger_role_arn
  s3_bucket_name          = module.s3.bucket_name
  s3_bucket_arn           = module.s3.bucket_arn
  dynamodb_table_name     = module.dynamodb.table_name

  depends_on = [module.iam, module.s3, module.dynamodb]
}

module "stepfunctions" {
  source              = "./stepfunctions"
  sf_role_arn         = module.iam.stepfunction_role_arn
  score_function_arn  = module.lambda.score_function_arn
  score_function_name = module.lambda.score_function_name
  s3_bucket_name      = module.s3.bucket_name
  account_id          = data.aws_caller_identity.current.account_id
  region              = var.region

  depends_on = [module.lambda]
}

resource "aws_lambda_permission" "s3_invoke_trigger" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.trigger_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3.bucket_arn
}

resource "aws_s3_bucket_notification" "input_trigger" {
  bucket = module.s3.bucket_name

  lambda_function {
    lambda_function_arn = module.lambda.trigger_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "input/"
    filter_suffix       = ".csv"
  }

  depends_on = [
    aws_lambda_permission.s3_invoke_trigger,
    module.stepfunctions,
  ]
}
