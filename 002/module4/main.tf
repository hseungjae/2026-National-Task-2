module "vpc" {
  source             = "./vpc"
  availability_zones = data.aws_availability_zones.available.names
}

module "iam" {
  source     = "./iam"
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

module "s3" {
  source            = "./s3"
  contestant_number = var.contestant_number
  account_id        = data.aws_caller_identity.current.account_id
}

module "sns" {
  source = "./sns"
}

module "dynamodb" {
  source = "./dynamodb"
}

module "msk" {
  source              = "./msk"
  vpc_id              = module.vpc.vpc_id
  private_subnet_a_id = module.vpc.private_subnet_a_id
  private_subnet_b_id = module.vpc.private_subnet_b_id

  depends_on = [module.vpc]
}

module "ec2" {
  source              = "./ec2"
  vpc_id              = module.vpc.vpc_id
  private_subnet_a_id = module.vpc.private_subnet_a_id
  public_subnet_a_id  = module.vpc.public_subnet_a_id
  instance_type       = var.instance_type
  ami_id              = data.aws_ami.amazon_linux_2023.id
  instance_profile    = module.iam.ec2_instance_profile_name
  msk_sg_id           = module.msk.msk_sg_id
  s3_bucket_name      = module.s3.bucket_name

  depends_on = [module.msk, module.iam, module.s3]
}

module "lambda" {
  source          = "./lambda"
  lambda_role_arn = module.iam.lambda_role_arn
  dynamodb_table  = module.dynamodb.table_name
  alert_topic_arn = module.sns.topic_arn
  s3_bucket_name  = module.s3.bucket_name
  msk_cluster_arn = module.msk.cluster_arn
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = [module.vpc.private_subnet_a_id, module.vpc.private_subnet_b_id]
  msk_sg_id       = module.msk.msk_sg_id

  depends_on = [module.msk, module.dynamodb, module.sns, module.s3, module.iam]
}
