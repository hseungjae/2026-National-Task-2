data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "al2023_ami_id" {
  name = "/aws/service/eks/optimized-ami/${var.k8s_version}/amazon-linux-2023/x86_64/standard/recommended/image_id"
}

data "aws_ami" "al2023" {
  owners = ["amazon"]
  filter {
    name   = "image-id"
    values = [data.aws_ssm_parameter.al2023_ami_id.value]
  }
}

locals {
  account_id    = data.aws_caller_identity.current.account_id
  alias_version = regex("v[0-9]+", data.aws_ami.al2023.name)
}
