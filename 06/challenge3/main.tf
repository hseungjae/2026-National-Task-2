module "iam" {
  source     = "./iam"
  account_id = data.aws_caller_identity.current.account_id
}

module "ec2" {
  source           = "./ec2"
  vpc_id           = data.aws_vpc.default.id
  subnet_id        = data.aws_subnets.default.ids[0]
  ami_id           = data.aws_ami.amazon_linux_2023.id
  instance_type    = var.instance_type
  key_name         = var.key_name
  ec2_role_name    = module.iam.ec2_role_name
  ec2_profile_name = module.iam.ec2_profile_name
}

module "cloudwatch" {
  source = "./cloudwatch"
}

module "lambda" {
  source            = "./lambda"
  recovery_role_arn = module.iam.recovery_lambda_role_arn
  updater_role_arn  = module.iam.updater_lambda_role_arn
  instance_id       = module.ec2.instance_id
}

module "eventbridge" {
  source               = "./eventbridge"
  lambda_arn           = module.lambda.recovery_function_arn
  lambda_function_name = module.lambda.recovery_function_name
  alarm_name           = module.cloudwatch.alarm_name

  depends_on = [module.lambda, module.cloudwatch]
}

module "logs" {
  source                = "./logs"
  updater_lambda_arn    = module.lambda.updater_function_arn
  updater_function_name = module.lambda.updater_function_name

  depends_on = [module.lambda]
}
