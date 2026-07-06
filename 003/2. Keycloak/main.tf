module "vpc" {
  source = "./vpc"
  prefix = var.prefix
  region = var.region
}

module "ec2" {
  source                  = "./ec2"
  prefix                  = var.prefix
  al2023_ami              = data.aws_ami.al2023_ami.id
  private_subnet          = module.vpc.private_subnet
  keycloak_sg             = module.vpc.keycloak_sg
  keycloak_admin_password = var.keycloak_admin_password
}

module "alb" {
  source      = "./alb"
  prefix      = var.prefix
  alb_sg      = module.vpc.alb_sg
  subnets     = module.vpc.public_subnets
  vpc_id      = module.vpc.vpc_id
  instance_id = module.ec2.instance_id
}

resource "time_sleep" "wait_alb" {
  depends_on      = [module.alb]
  create_duration = "90s"
}

module "keycloak" {
  source     = "./keycloak"
  depends_on = [time_sleep.wait_alb]
}

module "iam" {
  source       = "./iam"
  prefix       = var.prefix
  keycloak_url = "http://${data.aws_lb.keycloak.dns_name}"
  realm_name   = var.realm_name

  depends_on = [module.keycloak]
}

module "keycloak_users" {
  source              = "./keycloak-users"
  realm_id            = module.keycloak.realm_id
  dev_user_password   = var.dev_user_password
  infra_user_password = var.infra_user_password
  dev_role_arn        = module.iam.dev_role_arn
  infra_role_arn      = module.iam.infra_role_arn
  saml_provider_arn   = module.iam.saml_provider_arn

  depends_on = [module.iam]
}
