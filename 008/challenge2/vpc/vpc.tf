resource "aws_vpc" "client" {
  cidr_block           = "10.61.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "skills-lattice-client-vpc" }
}

resource "aws_internet_gateway" "client" {
  vpc_id = aws_vpc.client.id
  tags   = { Name = "skills-lattice-client-igw" }
}

resource "aws_subnet" "client_public" {
  vpc_id                  = aws_vpc.client.id
  cidr_block              = "10.61.1.0/24"
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "skills-lattice-client-public-subnet" }
}

resource "aws_route_table" "client_public" {
  vpc_id = aws_vpc.client.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.client.id
  }
  tags = { Name = "skills-lattice-client-public-rt" }
}

resource "aws_route_table_association" "client_public" {
  subnet_id      = aws_subnet.client_public.id
  route_table_id = aws_route_table.client_public.id
}

resource "aws_vpc" "service" {
  cidr_block           = "10.62.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "skills-lattice-service-vpc" }
}

resource "aws_internet_gateway" "service" {
  vpc_id = aws_vpc.service.id
  tags   = { Name = "skills-lattice-service-igw" }
}

resource "aws_subnet" "service_private" {
  vpc_id            = aws_vpc.service.id
  cidr_block        = "10.62.1.0/24"
  availability_zone = var.availability_zones[0]
  tags              = { Name = "skills-lattice-service-private-subnet" }
}

resource "aws_subnet" "service_public" {
  vpc_id                  = aws_vpc.service.id
  cidr_block              = "10.62.2.0/24"
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "skills-lattice-service-public-subnet" }
}

resource "aws_eip" "service_nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.service]
}

resource "aws_nat_gateway" "service" {
  allocation_id = aws_eip.service_nat.id
  subnet_id     = aws_subnet.service_public.id
  tags          = { Name = "skills-lattice-service-nat" }
}

resource "aws_route_table" "service_public" {
  vpc_id = aws_vpc.service.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.service.id
  }
  tags = { Name = "skills-lattice-service-public-rt" }
}

resource "aws_route_table_association" "service_public" {
  subnet_id      = aws_subnet.service_public.id
  route_table_id = aws_route_table.service_public.id
}

resource "aws_route_table" "service_private" {
  vpc_id = aws_vpc.service.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.service.id
  }
  tags = { Name = "skills-lattice-service-private-rt" }
}

resource "aws_route_table_association" "service_private" {
  subnet_id      = aws_subnet.service_private.id
  route_table_id = aws_route_table.service_private.id
}
