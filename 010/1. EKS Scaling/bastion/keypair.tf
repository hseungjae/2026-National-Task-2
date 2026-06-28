resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "bastion" {
  key_name   = "${var.prefix}-bastion-key"
  public_key = tls_private_key.bastion.public_key_openssh
}

resource "local_file" "bastion_pem" {
  content         = tls_private_key.bastion.private_key_pem
  filename        = "${path.root}/${var.prefix}-bastion-key.pem"
  file_permission = "0400"
}
