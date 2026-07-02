module "s3" {
  source        = "./s3"
  prefix = var.prefix
}

module "cloudfront" {
  source                = "./cloudfront"
  prefix                = var.prefix
  s3_bucket_id          = module.s3.bucket_id
  s3_bucket_domain_name = module.s3.bucket_regional_domain_name
  s3_bucket_arn         = module.s3.bucket_arn
}