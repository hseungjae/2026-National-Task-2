resource "aws_vpc" "ceh" {
  cidr_block           = "10.73.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "skills-ceh-vpc" }
}

resource "aws_internet_gateway" "ceh" {
  vpc_id = aws_vpc.ceh.id
  tags   = { Name = "skills-ceh-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.ceh.id
  cidr_block              = "10.73.1.0/24"
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "skills-ceh-public-subnet" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ceh.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ceh.id
  }
  tags = { Name = "skills-ceh-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
