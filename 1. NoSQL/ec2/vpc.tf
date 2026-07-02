resource "aws_default_vpc" "vpc" {}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.vpc.id]
  }
}