module "s3" {
  source = "./s3"
  prefix = var.prefix
  account_id = data.aws_caller_identity.current.account_id
}

module "cf" {
  source                      = "./cloudfront"
  prefix                      = var.prefix
  bucket_regional_domain_name = module.s3.bucket_regional_domain_name
  bucket_id                   = module.s3.bucket_id
}