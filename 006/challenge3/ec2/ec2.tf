locals {
  app_py_b64 = "ZnJvbSBmYXN0YXBpIGltcG9ydCBGYXN0QVBJCmZyb20gZGF0ZXRpbWUgaW1wb3J0IGRhdGV0aW1lCmltcG9ydCB1dmljb3JuCgphcHAgPSBGYXN0QVBJKCkKCkBhcHAuZ2V0KCIvIikKZGVmIHJvb3QoKToKICAgIHJldHVybiB7InN0YXR1cyI6ICJvayIsICJtZXNzYWdlIjogIldvcmxkU2tpbGxzIDIwMjYiLCAidGltZSI6IGRhdGV0aW1lLm5vdygpLmlzb2Zvcm1hdCgpfQoKQGFwcC5nZXQoIi9oZWFsdGgiKQpkZWYgaGVhbHRoKCk6CiAgICByZXR1cm4geyJzdGF0dXMiOiAiaGVhbHRoeSJ9CiAgICAKaWYgX19uYW1lX18gPT0gIl9fbWFpbl9fIjoKICAgIHV2aWNvcm4ucnVuKGFwcCwgaG9zdD0iMTI3LjAuMC4xIiwgcG9ydD04MDgwKQ=="
}

resource "aws_ssm_parameter" "app_py_backup" {
  name  = "/gj2026/event/app-py"
  type  = "String"
  value = base64decode(local.app_py_b64)

  tags = { Name = "gj2026-event-app-py" }
}

resource "tls_private_key" "event_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "event_key_pair" {
  key_name   = "gj2026-event-key"
  public_key = tls_private_key.event_key.public_key_openssh
}

resource "local_file" "event_private_key" {
  content         = tls_private_key.event_key.private_key_pem
  filename        = "${path.module}/gj2026-event-key.pem"
  file_permission = "0600"
}

resource "aws_security_group" "event" {
  name        = "gj2026-event-sg"
  description = "Security group for Cloud Event Handling EC2"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "FastAPI app"
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

  tags = { Name = "gj2026-event-sg" }
}

resource "aws_instance" "event" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.event.id]
  associate_public_ip_address = true
  iam_instance_profile        = var.ec2_profile_name
  key_name                    = aws_key_pair.event_key_pair.key_name

  user_data = base64encode(templatefile("${path.module}/userdata.sh.tpl", {
    app_py_b64 = local.app_py_b64
  }))

  tags = {
    Name = "gj2026-event-ec2"
  }
}
