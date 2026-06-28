module "vpc" {
  source = "./vpc"
  region = var.region
  prefix = var.prefix
}

module "ec2" {
  source     = "./ec2"
  vpc_id     = module.vpc.vpc_id
  pub_subnet = module.vpc.public_subnets
  ami_id     = data.aws_ami.al2023_ami.id
  prefix     = var.prefix
  userPin    = var.userPin
}

module "s3" {
  source   = "./s3"
  prefix   = var.prefix
  userPin  = var.userPin
}

module "msk" {
  source          = "./msk"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  app_sg_id       = module.ec2.app_sg_id
}

module "dynamodb" {
  source = "./dynamodb"
}

module "lambda" {
  source             = "./lambda"
  region             = var.region
  prefix             = var.prefix
  dynamodb_table_arn = module.dynamodb.table_arn
  table_name         = module.dynamodb.table_name
  msk_cluster_arn    = module.msk.cluster_arn
  private_subnets    = module.vpc.private_subnets
}
