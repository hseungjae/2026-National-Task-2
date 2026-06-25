## Hub VPC
resource "aws_vpc" "hub" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "wsc-hub-vpc" }
}

resource "aws_internet_gateway" "hub" {
  vpc_id = aws_vpc.hub.id
  tags   = { Name = "wsc-hub-igw" }
}

resource "aws_subnet" "hub_public_a" {
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "wsc-hub-sn-pub-a" }
}

resource "aws_subnet" "hub_public_c" {
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-1c"
  map_public_ip_on_launch = true
  tags                    = { Name = "wsc-hub-sn-pub-c" }
}

resource "aws_route_table" "hub_public" {
  vpc_id = aws_vpc.hub.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hub.id
  }
  tags = { Name = "wsc-hub-rt-pub" }
}

resource "aws_route_table_association" "hub_public_a" {
  subnet_id      = aws_subnet.hub_public_a.id
  route_table_id = aws_route_table.hub_public.id
}

resource "aws_route_table_association" "hub_public_c" {
  subnet_id      = aws_subnet.hub_public_c.id
  route_table_id = aws_route_table.hub_public.id
}

## Spoke VPC
resource "aws_vpc" "spoke" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "wsc-spoke-vpc" }
}

resource "aws_internet_gateway" "spoke" {
  vpc_id = aws_vpc.spoke.id
  tags   = { Name = "wsc-spoke-igw" }
}

resource "aws_subnet" "spoke_public_a" {
  vpc_id                  = aws_vpc.spoke.id
  cidr_block              = "192.168.0.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "wsc-spoke-sn-pub-a" }
}

resource "aws_subnet" "spoke_public_c" {
  vpc_id                  = aws_vpc.spoke.id
  cidr_block              = "192.168.1.0/24"
  availability_zone       = "ap-southeast-1c"
  map_public_ip_on_launch = true
  tags                    = { Name = "wsc-spoke-sn-pub-c" }
}

resource "aws_subnet" "spoke_private_a" {
  vpc_id            = aws_vpc.spoke.id
  cidr_block        = "192.168.2.0/24"
  availability_zone = "ap-southeast-1a"
  tags              = { Name = "wsc-spoke-sn-priv-a" }
}

resource "aws_subnet" "spoke_private_c" {
  vpc_id            = aws_vpc.spoke.id
  cidr_block        = "192.168.3.0/24"
  availability_zone = "ap-southeast-1c"
  tags              = { Name = "wsc-spoke-sn-priv-c" }
}

resource "aws_eip" "spoke_nat_a" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.spoke]
}

resource "aws_nat_gateway" "spoke_a" {
  allocation_id = aws_eip.spoke_nat_a.id
  subnet_id     = aws_subnet.spoke_public_a.id
  tags          = { Name = "wsc-spoke-nat-a" }
  depends_on    = [aws_internet_gateway.spoke]
}

resource "aws_eip" "spoke_nat_c" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.spoke]
}

resource "aws_nat_gateway" "spoke_c" {
  allocation_id = aws_eip.spoke_nat_c.id
  subnet_id     = aws_subnet.spoke_public_c.id
  tags          = { Name = "wsc-spoke-nat-c" }
  depends_on    = [aws_internet_gateway.spoke]
}

resource "aws_route_table" "spoke_public" {
  vpc_id = aws_vpc.spoke.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.spoke.id
  }
  tags = { Name = "wsc-spoke-rt-pub" }
}

resource "aws_route_table_association" "spoke_public_a" {
  subnet_id      = aws_subnet.spoke_public_a.id
  route_table_id = aws_route_table.spoke_public.id
}

resource "aws_route_table_association" "spoke_public_c" {
  subnet_id      = aws_subnet.spoke_public_c.id
  route_table_id = aws_route_table.spoke_public.id
}

resource "aws_route_table" "spoke_private_a" {
  vpc_id = aws_vpc.spoke.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.spoke_a.id
  }
  tags = { Name = "wsc-spoke-rt-priv-a" }
}

resource "aws_route_table" "spoke_private_c" {
  vpc_id = aws_vpc.spoke.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.spoke_c.id
  }
  tags = { Name = "wsc-spoke-rt-priv-c" }
}

resource "aws_route_table_association" "spoke_private_a" {
  subnet_id      = aws_subnet.spoke_private_a.id
  route_table_id = aws_route_table.spoke_private_a.id
}

resource "aws_route_table_association" "spoke_private_c" {
  subnet_id      = aws_subnet.spoke_private_c.id
  route_table_id = aws_route_table.spoke_private_c.id
}
