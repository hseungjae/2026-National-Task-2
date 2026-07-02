# ── Client VPN 보안 그룹 (UDP 1194 inbound) ──────────────────────────────────
resource "aws_security_group" "vpn" {
  name        = "wsc2026-vpn-sg"
  description = "Client VPN Security Group"
  vpc_id      = var.vpc_id

  ingress {
    description = "OpenVPN"
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "wsc2026-vpn-sg" }
}

# ── Client VPN Endpoint ──────────────────────────────────────────────────────
# - IPv4 / 상호(인증서) 인증 / UDP 1194
# - split_tunnel = true : 엔드포인트 경로와 일치하는 트래픽만 터널 통과
resource "aws_ec2_client_vpn_endpoint" "wsc_vpn" {
  description            = "wsc-vpn"
  client_cidr_block      = "172.16.0.0/22"
  server_certificate_arn = var.server_certificate_arn
  transport_protocol     = "udp"
  vpn_port               = 1194
  split_tunnel           = true
  vpc_id                 = var.vpc_id
  security_group_ids     = [aws_security_group.vpn.id]

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.client_certificate_arn
  }

  connection_log_options {
    enabled = false
  }

  tags = { Name = "wsc-vpn" }
}

# ── vpn-sn-b 서브넷 연결 ─────────────────────────────────────────────────────
resource "aws_ec2_client_vpn_network_association" "vpn_sn_b" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.wsc_vpn.id
  subnet_id              = var.vpn_subnet_id
}

# ── 인증 규칙 (VPC 대역 접근 허용 → vpn-ec2 SSH 접속 가능) ────────────────────
resource "aws_ec2_client_vpn_authorization_rule" "vpc" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.wsc_vpn.id
  target_network_cidr    = var.vpc_cidr
  authorize_all_groups   = true
}
