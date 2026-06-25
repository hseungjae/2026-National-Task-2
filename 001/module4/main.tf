# ── Module 4: VPN (ap-southeast-1) ───────────────────────────────────────────
# network → ec2 / vpn

module "network" {
  source = "./network"
}

resource "tls_private_key" "vpn_ec2" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "vpn_ec2_private_key" {
  content         = tls_private_key.vpn_ec2.private_key_pem
  filename        = "${path.module}/ec2/wsc2026-vpn.pem"
  file_permission = "0600"
}

module "ec2" {
  source     = "./ec2"
  vpc_id     = module.network.vpc_id
  vpc_cidr   = module.network.vpc_cidr
  subnet_id  = module.network.vpn_sn_b_id
  ami_id     = data.aws_ami.al2023.id
  public_key = tls_private_key.vpn_ec2.public_key_openssh
}

module "vpn" {
  source                 = "./vpn"
  vpc_id                 = module.network.vpc_id
  vpc_cidr               = module.network.vpc_cidr
  vpn_subnet_id          = module.network.vpn_sn_b_id
  server_certificate_arn = data.aws_acm_certificate.server.arn
  client_certificate_arn = data.aws_acm_certificate.client.arn
}
