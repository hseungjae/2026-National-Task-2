resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}

output "vpc_id" {
  value = aws_default_vpc.default.id
}

output "subnet_ids" {
  value = data.aws_subnets.default.ids
}
