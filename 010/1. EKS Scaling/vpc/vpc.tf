# Public(hub) 영역은 모듈로 구성 - VPC / hub 서브넷 / IGW / hub-rtb
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.prefix}-vpc"
  cidr = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support   = true

  manage_default_route_table = false

  azs = [
    "${var.region}a",
    "${var.region}b"
  ]

  public_subnets = ["10.0.0.0/24", "10.0.1.0/24"]

  public_subnet_names = [
    "${var.prefix}-pub-a",
    "${var.prefix}-pub-b"
  ]

  public_route_table_tags = {
    Name = "${var.prefix}-pub-rt"
  }

  igw_tags = {
    Name = "${var.prefix}-igw"
  }
}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["${var.prefix}-vpc"]
  }

  depends_on = [module.vpc]
}
