module "vpc" {
  source             = "./vpc"
  availability_zones = data.aws_availability_zones.available.names
}

module "sns" {
  source = "./sns"
}

module "ec2" {
  source           = "./ec2"
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_a_id
  instance_type    = var.instance_type
  ami_id           = data.aws_ami.amazon_linux_2023.id
}

module "iam" {
  source    = "./iam"
  topic_arn = module.sns.topic_arn
}

module "s3" {
  source     = "./s3"
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

module "cloudtrail" {
  source         = "./cloudtrail"
  s3_bucket_name = module.s3.bucket_name

  depends_on = [module.s3]
}

module "lambda" {
  source            = "./lambda"
  lambda_role_arn   = module.iam.lambda_role_arn
  topic_arn         = module.sns.topic_arn
  sg_id             = module.ec2.sg_id
  instance_id       = module.ec2.instance_id
  instance_type     = var.instance_type

  depends_on = [module.ec2, module.sns, module.iam]
}

module "eventbridge" {
  source        = "./eventbridge"
  lambda_arns   = module.lambda.function_arns
  lambda_names  = module.lambda.function_names

  depends_on = [module.cloudtrail, module.lambda]
}
