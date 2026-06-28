module "vpc" {
  source = "./vpc"
}

module "rds" {
  source     = "./rds"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.subnet_ids
}

module "secretmanager" {
  source         = "./secretmanager"
  rds_secret_arn = module.rds.secret_arn

  depends_on = [ module.rds ]
}

module "lambda" {
  source     = "./lambda"
  rds_arn    = module.rds.cluster_arn
  secret_arn = module.secretmanager.secret_arn
}
