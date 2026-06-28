resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "ssh" {
  key_name   = "${var.prefix}-ssh-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "local_file" "ssh_pem" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.root}/${var.prefix}-ssh-key.pem"
  file_permission = "0400"
}
