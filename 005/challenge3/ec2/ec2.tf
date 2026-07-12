resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion" {
  key_name   = "wsc-logging-bastion-key"
  public_key = tls_private_key.bastion.public_key_openssh
}

resource "local_file" "bastion_key" {
  content         = tls_private_key.bastion.private_key_pem
  filename        = "${path.module}/wsc-logging-bastion-key.pem"
  file_permission = "0600"
}

resource "aws_security_group" "bastion" {
  name   = "wsc-logging-bastion-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "wsc-logging-bastion-sg" }
}

resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = "t3.medium"
  subnet_id                   = var.public_subnet_a_id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  iam_instance_profile        = var.bastion_instance_profile_name
  associate_public_ip_address = true
  key_name                    = aws_key_pair.bastion.key_name

  user_data = <<-EOF
    #!/bin/bash
    echo "instance ready"
  EOF

  tags = { Name = "wsc-log-app-bastion" }
}
