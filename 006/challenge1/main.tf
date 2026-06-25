module "s3" {
  source     = "./s3"
  account_id = data.aws_caller_identity.current.account_id
  beonho     = var.beonho
}

module "iam" {
  source      = "./iam"
  bucket_name = module.s3.bucket_name
}

module "lambda" {
  source       = "./lambda"
  role_arn     = module.iam.lambda_role_arn
  bucket_name  = module.s3.bucket_name
}

module "cloudfront" {
  source              = "./cloudfront"
  lambda_url          = module.lambda.rotate_function_url
  request_lambda_arn  = module.lambda.request_qualified_arn
  response_lambda_arn = module.lambda.response_qualified_arn
}

