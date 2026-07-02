# ── VPC ─────────────────────────────────────────────────────────────────────
resource "aws_vpc" "vpn_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "wsc2026-vpn-vpc" }
}

# ── Subnets (pub: igw / vpn: nat) ────────────────────────────────────────────
resource "aws_subnet" "pub_sn_a" {
  vpc_id            = aws_vpc.vpn_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"
  tags              = { Name = "wsc2026-pub-sn-a" }
}

resource "aws_subnet" "pub_sn_b" {
  vpc_id            = aws_vpc.vpn_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-1b"
  tags              = { Name = "wsc2026-pub-sn-b" }
}

resource "aws_subnet" "vpn_sn_a" {
  vpc_id            = aws_vpc.vpn_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-southeast-1a"
  tags              = { Name = "wsc2026-vpn-sn-a" }
}

resource "aws_subnet" "vpn_sn_b" {
  vpc_id            = aws_vpc.vpn_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-southeast-1b"
  tags              = { Name = "wsc2026-vpn-sn-b" }
}

# ── IGW + NAT ────────────────────────────────────────────────────────────────
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpn_vpc.id
  tags   = { Name = "wsc2026-vpn-igw" }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "wsc2026-vpn-nat-eip" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.pub_sn_a.id
  tags          = { Name = "wsc2026-vpn-nat" }

  depends_on = [aws_internet_gateway.igw]
}

# ── Route Tables ─────────────────────────────────────────────────────────────
# pub → IGW
resource "aws_route_table" "pub" {
  vpc_id = aws_vpc.vpn_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "wsc2026-pub-rt" }
}

resource "aws_route_table_association" "pub_a" {
  subnet_id      = aws_subnet.pub_sn_a.id
  route_table_id = aws_route_table.pub.id
}

resource "aws_route_table_association" "pub_b" {
  subnet_id      = aws_subnet.pub_sn_b.id
  route_table_id = aws_route_table.pub.id
}

# vpn → NAT
resource "aws_route_table" "vpn" {
  vpc_id = aws_vpc.vpn_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = { Name = "wsc2026-vpn-rt" }
}

resource "aws_route_table_association" "vpn_a" {
  subnet_id      = aws_subnet.vpn_sn_a.id
  route_table_id = aws_route_table.vpn.id
}

resource "aws_route_table_association" "vpn_b" {
  subnet_id      = aws_subnet.vpn_sn_b.id
  route_table_id = aws_route_table.vpn.id
}
