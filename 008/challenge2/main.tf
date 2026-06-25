module "vpc" {
  source             = "./vpc"
  availability_zones = data.aws_availability_zones.available.names
}

module "iam" {
  source = "./iam"
}

module "ec2" {
  source                    = "./ec2"
  client_public_subnet_id   = module.vpc.client_public_subnet_id
  service_private_subnet_id = module.vpc.service_private_subnet_id
  client_vpc_id             = module.vpc.client_vpc_id
  service_vpc_id            = module.vpc.service_vpc_id
  instance_profile_name     = module.iam.instance_profile_name
  instance_type             = var.instance_type
  ami_id                    = data.aws_ami.amazon_linux_2023.id
}

module "lattice" {
  source         = "./lattice"
  client_vpc_id  = module.vpc.client_vpc_id
  service_vpc_id = module.vpc.service_vpc_id
  service_ec2_id = module.ec2.service_ec2_id

  depends_on = [module.ec2]
}
