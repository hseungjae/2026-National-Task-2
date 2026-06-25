resource "aws_vpc" "analytics" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "analytics-vpc" }
}

resource "aws_internet_gateway" "analytics" {
  vpc_id = aws_vpc.analytics.id
  tags   = { Name = "analytics-igw" }
}

resource "aws_subnet" "pub_a" {
  vpc_id                  = aws_vpc.analytics.id
  cidr_block              = "10.20.0.0/24"
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "analytics-pub-a" }
}

resource "aws_subnet" "pub_b" {
  vpc_id                  = aws_vpc.analytics.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = true
  tags                    = { Name = "analytics-pub-b" }
}

resource "aws_subnet" "priv_a" {
  vpc_id            = aws_vpc.analytics.id
  cidr_block        = "10.20.100.0/24"
  availability_zone = var.availability_zones[0]
  tags              = { Name = "analytics-priv-a" }
}

resource "aws_subnet" "priv_b" {
  vpc_id            = aws_vpc.analytics.id
  cidr_block        = "10.20.101.0/24"
  availability_zone = var.availability_zones[1]
  tags              = { Name = "analytics-priv-b" }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "analytics-nat-eip" }
}

resource "aws_nat_gateway" "analytics" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.pub_a.id
  tags          = { Name = "analytics-ngw" }

  depends_on = [aws_internet_gateway.analytics]
}

resource "aws_route_table" "pub" {
  vpc_id = aws_vpc.analytics.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.analytics.id
  }

  tags = { Name = "analytics-pub-rtb" }
}

resource "aws_route_table_association" "pub_a" {
  subnet_id      = aws_subnet.pub_a.id
  route_table_id = aws_route_table.pub.id
}

resource "aws_route_table_association" "pub_b" {
  subnet_id      = aws_subnet.pub_b.id
  route_table_id = aws_route_table.pub.id
}

resource "aws_route_table" "priv_a" {
  vpc_id = aws_vpc.analytics.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.analytics.id
  }

  tags = { Name = "analytics-priv-a-rtb" }
}

resource "aws_route_table" "priv_b" {
  vpc_id = aws_vpc.analytics.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.analytics.id
  }

  tags = { Name = "analytics-priv-b-rtb" }
}

resource "aws_route_table_association" "priv_a" {
  subnet_id      = aws_subnet.priv_a.id
  route_table_id = aws_route_table.priv_a.id
}

resource "aws_route_table_association" "priv_b" {
  subnet_id      = aws_subnet.priv_b.id
  route_table_id = aws_route_table.priv_b.id
}
