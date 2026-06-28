resource "aws_vpc" "event" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "event-vpc" }
}

resource "aws_internet_gateway" "event" {
  vpc_id = aws_vpc.event.id
  tags   = { Name = "event-igw" }
}

resource "aws_subnet" "pub_a" {
  vpc_id                  = aws_vpc.event.id
  cidr_block              = "172.16.0.0/24"
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "event-pub-a" }
}

resource "aws_subnet" "pub_b" {
  vpc_id                  = aws_vpc.event.id
  cidr_block              = "172.16.1.0/24"
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = true
  tags                    = { Name = "event-pub-b" }
}

resource "aws_route_table" "pub" {
  vpc_id = aws_vpc.event.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.event.id
  }

  tags = { Name = "event-pub-rtb" }
}

resource "aws_route_table_association" "pub_a" {
  subnet_id      = aws_subnet.pub_a.id
  route_table_id = aws_route_table.pub.id
}

resource "aws_route_table_association" "pub_b" {
  subnet_id      = aws_subnet.pub_b.id
  route_table_id = aws_route_table.pub.id
}
