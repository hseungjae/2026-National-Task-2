module "ec2" {
  source                  = "./ec2"
  vpc_id                  = data.aws_vpc.default.id
  subnet_id               = data.aws_subnets.default.ids[0]
  ami_id                  = data.aws_ami.amazon_linux_2023.id
  instance_type           = var.instance_type
  key_name                = var.key_name
  keycloak_admin_password = var.keycloak_admin_password
}

module "iam" {
  source     = "./iam"
  account_id = data.aws_caller_identity.current.account_id
  keycloak_domain = module.ec2.keycloak_domain
}

output "keycloak_url" {
  value = "https://${module.ec2.keycloak_domain}"
}

output "keycloak_public_ip" {
  value = module.ec2.public_ip
}

output "dev_team_role_arn" {
  value = module.iam.dev_team_role_arn
}

output "sec_team_role_arn" {
  value = module.iam.sec_team_role_arn
}

output "oidc_provider_arn" {
  value = module.iam.oidc_provider_arn
}
