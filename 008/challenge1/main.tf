module "vpc" {
  source             = "./vpc"
  availability_zones = data.aws_availability_zones.available.names
}

module "kms" {
  source = "./kms"
}

module "docdb" {
  source              = "./docdb"
  vpc_id              = module.vpc.vpc_id
  private_subnet_a_id = module.vpc.private_subnet_a_id
  private_subnet_b_id = module.vpc.private_subnet_b_id
  docdb_sg_id         = module.vpc.docdb_sg_id
  kms_key_arn         = module.kms.kms_key_arn
  docdb_password      = var.docdb_password
}

module "secrets" {
  source           = "./secrets"
  cluster_endpoint = module.docdb.cluster_endpoint
  master_username  = module.docdb.master_username
  docdb_password   = var.docdb_password
}

module "iam" {
  source     = "./iam"
  secret_arn = module.secrets.secret_arn
}

module "ec2" {
  source                = "./ec2"
  public_subnet_id      = module.vpc.public_subnet_id
  client_sg_id          = module.vpc.client_sg_id
  instance_profile_name = module.iam.instance_profile_name
  instance_type         = var.instance_type
  ami_id                = data.aws_ami.amazon_linux_2023.id

  depends_on = [module.docdb, module.secrets]
}
