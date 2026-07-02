data "aws_caller_identity" "current" {}

resource "null_resource" "ensure_default_vpc" {
  provisioner "local-exec" {
    interpreter = ["powershell", "-Command"]
    command     = "aws ec2 create-default-vpc --region ap-northeast-2; exit 0"
  }
}

data "aws_vpc" "default" {
  default    = true
  depends_on = [null_resource.ensure_default_vpc]
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*kernel-6.1*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
