module "s3" {
  source = "./s3"
  prefix = var.prefix
  userPin = var.userPin
}

module "lambda" {
  source      = "./lambda"
  prefix      = var.prefix
  bucket_name = module.s3.bucket_name
  s3_arn      = module.s3.bucket_arn
}

module "cf" {
  source                       = "./cloudfront"
  prefix                       = var.prefix
  bucket_name                  = module.s3.bucket_name
  bucket_arn                   = module.s3.bucket_arn
  bucket_regional_domain_name  = module.s3.bucket_regional_domain_name
  lambda_arn                   = module.lambda.qualified_arn
}