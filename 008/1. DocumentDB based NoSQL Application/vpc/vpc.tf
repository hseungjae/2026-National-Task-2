resource "aws_vpc" "nosql" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "skills-nosql-vpc" }
}

resource "aws_internet_gateway" "nosql" {
  vpc_id = aws_vpc.nosql.id
  tags   = { Name = "skills-nosql-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.nosql.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "skills-nosql-public-subnet" }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.nosql.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = var.availability_zones[0]
  tags              = { Name = "skills-nosql-private-subnet-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.nosql.id
  cidr_block        = "10.10.3.0/24"
  availability_zone = var.availability_zones[1]
  tags              = { Name = "skills-nosql-private-subnet-b" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.nosql.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nosql.id
  }
  tags = { Name = "skills-nosql-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "client_ec2" {
  name        = "skills-nosql-client-sg"
  description = "Client EC2 security group"
  vpc_id      = aws_vpc.nosql.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "skills-nosql-client-sg" }
}

resource "aws_security_group" "docdb" {
  name        = "skills-nosql-docdb-sg"
  description = "DocumentDB security group - allow from client EC2 only"
  vpc_id      = aws_vpc.nosql.id

  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.client_ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "skills-nosql-docdb-sg" }
}
