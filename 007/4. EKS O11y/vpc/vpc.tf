resource "aws_default_vpc" "vpc" {}

# 기본 VPC의 각 AZ 기본 서브넷 (Multi-AZ)
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.vpc.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}
