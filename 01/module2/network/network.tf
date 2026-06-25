# ── VPC ─────────────────────────────────────────────────────────────────────
resource "aws_vpc" "db_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "wsc2026-db-vpc" }
}

# ── Subnets (2 AZ × private/public) ──────────────────────────────────────────
resource "aws_subnet" "db_sn_a" {
  vpc_id            = aws_vpc.db_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"
  tags              = { Name = "wsc2026-db-sn-a" }
}

resource "aws_subnet" "db_sn_c" {
  vpc_id            = aws_vpc.db_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-1c"
  tags              = { Name = "wsc2026-db-sn-c" }
}

resource "aws_subnet" "pub_sn_a" {
  vpc_id            = aws_vpc.db_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-1a"
  tags              = { Name = "wsc2026-pub-sn-a" }
}

resource "aws_subnet" "pub_sn_c" {
  vpc_id            = aws_vpc.db_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-northeast-1c"
  tags              = { Name = "wsc2026-pub-sn-c" }
}

# ── Security Group (RDS / Proxy / Lambda 공용, VPC 내부 3306 허용) ────────────
resource "aws_security_group" "rds_sg" {
  name        = "wsc2026-rds-sg"
  description = "wsc2026 RDS Security Group"
  vpc_id      = aws_vpc.db_vpc.id

  ingress {
    description = "MySQL from within VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "wsc2026-rds-sg" }
}

# ── IGW + NAT Gateway (프라이빗 서브넷 → 인터넷 경로) ───────────────────────
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.db_vpc.id
  tags   = { Name = "wsc2026-db-igw" }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "wsc2026-nat-eip" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.pub_sn_a.id
  tags          = { Name = "wsc2026-nat" }
  depends_on    = [aws_internet_gateway.igw]
}

# ── Route Tables ─────────────────────────────────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.db_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "wsc2026-public-rt" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.db_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = { Name = "wsc2026-private-rt" }
}

resource "aws_route_table_association" "pub_a" {
  subnet_id      = aws_subnet.pub_sn_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "pub_c" {
  subnet_id      = aws_subnet.pub_sn_c.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "db_a" {
  subnet_id      = aws_subnet.db_sn_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "db_c" {
  subnet_id      = aws_subnet.db_sn_c.id
  route_table_id = aws_route_table.private.id
}

# ── DB Subnet Group (프라이빗 서브넷에 RDS 배치) ─────────────────────────────
resource "aws_db_subnet_group" "this" {
  name       = "wsc2026-db-subnet-group"
  subnet_ids = [aws_subnet.db_sn_a.id, aws_subnet.db_sn_c.id]

  tags = { Name = "wsc2026-db-subnet-group" }
}
