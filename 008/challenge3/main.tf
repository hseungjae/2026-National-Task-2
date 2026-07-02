module "vpc" {
  source             = "./vpc"
  availability_zones = data.aws_availability_zones.available.names
}

module "ec2" {
  source           = "./ec2"
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_id
  instance_type    = var.instance_type
  ami_id           = data.aws_ami.amazon_linux_2023.id
}

module "sns" {
  source = "./sns"
}

module "iam" {
  source    = "./iam"
  topic_arn = module.sns.topic_arn
}

module "lambda" {
  source          = "./lambda"
  role_arn        = module.iam.lambda_role_arn
  protected_sg_id = module.ec2.protected_sg_id
  topic_arn       = module.sns.topic_arn
}

module "s3" {
  source     = "./s3"
  account_id = data.aws_caller_identity.current.account_id
}

module "cloudtrail" {
  source         = "./cloudtrail"
  s3_bucket_name = module.s3.bucket_name
}

module "eventbridge" {
  source               = "./eventbridge"
  lambda_arn           = module.lambda.function_arn
  lambda_function_name = module.lambda.function_name

  depends_on = [module.cloudtrail, module.lambda]
}
