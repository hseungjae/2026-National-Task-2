resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion" {
  key_name   = "wsc-scaling-bastion-key"
  public_key = tls_private_key.bastion.public_key_openssh
}

resource "local_file" "bastion_key" {
  content         = tls_private_key.bastion.private_key_pem
  filename        = "${path.module}/wsc-scaling-bastion-key.pem"
  file_permission = "0600"
}

resource "aws_security_group" "bastion" {
  name        = "wsc-scaling-bastion-sg"
  description = "Bastion security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "wsc-scaling-bastion-sg" }
}

resource "aws_instance" "bastion" {
  ami                    = var.ami_id
  instance_type          = "t3.medium"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  iam_instance_profile   = var.instance_profile_name
  key_name               = aws_key_pair.bastion.key_name

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # kubectl 설치
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/$${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/

    # eksctl 설치
    ARCH=amd64
    PLATFORM=$(uname -s)_$ARCH
    curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$${PLATFORM}.tar.gz"
    tar -xzf eksctl_$${PLATFORM}.tar.gz -C /tmp
    mv /tmp/eksctl /usr/local/bin/

    # helm 설치
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  EOF

  tags = {
    Name = "wsc-scaling-bastion"
  }
}
