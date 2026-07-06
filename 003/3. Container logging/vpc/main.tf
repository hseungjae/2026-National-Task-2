module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.prefix}-logging-vpc"
  cidr = "10.30.0.0/16"

  azs = ["${var.region}a", "${var.region}c"]

  public_subnets  = ["10.30.1.0/24", "10.30.2.0/24"]
  private_subnets = ["10.30.10.0/24", "10.30.20.0/24"]

  public_subnet_names = [
    "${var.prefix}-public-subnet-a",
    "${var.prefix}-public-subnet-c"
  ]
  private_subnet_names = [
    "${var.prefix}-private-subnet-a",
    "${var.prefix}-private-subnet-c"
  ]

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway   = true
  single_nat_gateway   = true

  igw_tags = {
    Name = "${var.prefix}-logging-igw"
  }
}
