resource "aws_vpc" "this" {
  cidr_block           = "10.3.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "wsc-logging-vpc" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "wsc-logging-igw" }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.3.0.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true
  tags = {
    Name                                        = "wsc-logging-sn-pub-a"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/wsc-logging-cluster" = "owned"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.3.1.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true
  tags = {
    Name                                        = "wsc-logging-sn-pub-c"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/wsc-logging-cluster" = "owned"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.3.2.0/24"
  availability_zone = "ap-northeast-1a"
  tags = {
    Name                                        = "wsc-logging-sn-priv-a"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/wsc-logging-cluster" = "owned"
  }
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.3.3.0/24"
  availability_zone = "ap-northeast-1c"
  tags = {
    Name                                        = "wsc-logging-sn-priv-c"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/wsc-logging-cluster" = "owned"
  }
}

resource "aws_eip" "nat_a" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.this]
}

resource "aws_eip" "nat_c" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id
  tags          = { Name = "wsc-logging-nat-a" }
  depends_on    = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "c" {
  allocation_id = aws_eip.nat_c.id
  subnet_id     = aws_subnet.public_c.id
  tags          = { Name = "wsc-logging-nat-c" }
  depends_on    = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = { Name = "wsc-logging-rt-pub" }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.a.id
  }
  tags = { Name = "wsc-logging-rt-priv-a" }
}

resource "aws_route_table" "private_c" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.c.id
  }
  tags = { Name = "wsc-logging-rt-priv-c" }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_c" {
  subnet_id      = aws_subnet.private_c.id
  route_table_id = aws_route_table.private_c.id
}
