# al2023 AMI
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# 사전에 ACM 으로 import 한 서버/클라이언트 인증서 조회
data "aws_acm_certificate" "server" {
  domain   = var.server_cert_domain
  statuses = ["ISSUED"]
}

data "aws_acm_certificate" "client" {
  domain   = var.client_cert_domain
  statuses = ["ISSUED"]
}
