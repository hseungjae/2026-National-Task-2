data "aws_ami" "al2023_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*kernel-6.1*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}


data "aws_caller_identity" "current" {}

# ALB DNS를 이름으로 조회 (module.alb apply 후 사용 가능)
data "aws_lb" "keycloak" {
  name = "${var.prefix}-keycloak-alb"

  depends_on = [module.alb]
}
