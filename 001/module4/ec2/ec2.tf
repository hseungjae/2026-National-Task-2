# ── EC2 보안 그룹 (VPN 클라이언트 / VPC 내부에서 SSH 허용) ───────────────────
resource "aws_security_group" "ec2" {
  name        = "wsc2026-ec2-sg"
  description = "vpn-ec2 Security Group"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from VPN clients"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/22", var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "wsc2026-ec2-sg" }
}

# ── Key Pair ─────────────────────────────────────────────────────────────────
resource "aws_key_pair" "vpn" {
  key_name   = "wsc2026-vpn-key"
  public_key = var.public_key
}

# ── EC2 (vpn-sn-b, al2023, t3.micro, 퍼블릭 IP 없음) ─────────────────────────
resource "aws_instance" "vpn_ec2" {
  ami                         = var.ami_id
  instance_type               = "t3.micro"
  subnet_id                   = var.subnet_id
  key_name                    = aws_key_pair.vpn.key_name
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = false

  tags = { Name = "vpn-ec2" }
}
