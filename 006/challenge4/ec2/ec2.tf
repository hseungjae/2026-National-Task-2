resource "aws_iam_role" "ec2" {
  name = "gj2026-keycloak-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "gj2026-keycloak-ec2-role" }
}

resource "aws_iam_role_policy_attachment" "ec2_admin" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "gj2026-keycloak-ec2-profile"
  role = aws_iam_role.ec2.name
}

resource "tls_private_key" "keycloak_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "keycloak_key_pair" {
  key_name   = "gj2026-keycloak-key"
  public_key = tls_private_key.keycloak_key.public_key_openssh
}

resource "local_file" "keycloak_private_key" {
  content         = tls_private_key.keycloak_key.private_key_pem
  filename        = "${path.module}/gj2026-keycloak-key.pem"
  file_permission = "0600"
}

resource "aws_eip" "keycloak" {
  domain = "vpc"
  tags   = { Name = "gj2026-keycloak-eip" }
}

resource "aws_eip_association" "keycloak" {
  instance_id   = aws_instance.keycloak.id
  allocation_id = aws_eip.keycloak.id
}

resource "aws_security_group" "keycloak" {
  name        = "gj2026-keycloak-sg"
  description = "Security group for Keycloak"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP (certbot)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS (Keycloak)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Keycloak HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "gj2026-keycloak-sg" }
}

resource "aws_instance" "keycloak" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.keycloak.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  key_name                    = aws_key_pair.keycloak_key_pair.key_name

  user_data = base64encode(templatefile("${path.module}/userdata.sh.tpl", {
    keycloak_admin_password = var.keycloak_admin_password
    public_ip               = aws_eip.keycloak.public_ip
  }))

  tags = {
    Name = "gj2026-keycloak-ec2"
  }

  lifecycle {
    ignore_changes = [associate_public_ip_address]
  }
}
