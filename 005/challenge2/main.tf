module "vpc" {
  source = "./vpc"
}

module "iam" {
  source = "./iam"
}

module "ec2" {
  source                    = "./ec2"
  ami_id                    = data.aws_ami.amazon_linux_2023.id
  hub_public_subnet_a_id    = module.vpc.hub_public_subnet_a_id
  spoke_private_subnet_a_id = module.vpc.spoke_private_subnet_a_id
  hub_vpc_id                = module.vpc.hub_vpc_id
  spoke_vpc_id              = module.vpc.spoke_vpc_id
  bastion_profile_name      = module.iam.bastion_instance_profile_name
  app_profile_name          = module.iam.app_instance_profile_name
}

module "alb" {
  source                    = "./alb"
  spoke_vpc_id              = module.vpc.spoke_vpc_id
  spoke_private_subnet_a_id = module.vpc.spoke_private_subnet_a_id
  spoke_private_subnet_c_id = module.vpc.spoke_private_subnet_c_id
  app_v1_id                 = module.ec2.app_v1_id
  app_v2_id                 = module.ec2.app_v2_id
}

module "lattice" {
  source               = "./lattice"
  hub_vpc_id           = module.vpc.hub_vpc_id
  spoke_vpc_id         = module.vpc.spoke_vpc_id
  alb_arn              = module.alb.alb_arn
  spoke_private_sg_id  = module.ec2.app_sg_id
}
