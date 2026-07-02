resource "aws_default_vpc" "vpc" {}

data "aws_availability_zones" "available" {
  exclude_names = ["us-east-1e"]
}

data "aws_subnet" "default" {
  for_each = toset(data.aws_availability_zones.available.names)

  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.vpc.id]
  }
  filter {
    name   = "availabilityZone"
    values = [each.value]
  }

  default_for_az = true
}

resource "aws_ec2_tag" "subnet_karpenter" {
  for_each    = data.aws_subnet.default
  resource_id = each.value.id
  key         = "karpenter.sh/discovery"
  value       = "${var.prefix}-eks-cluster"
}
