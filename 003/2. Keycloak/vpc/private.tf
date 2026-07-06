resource "aws_subnet" "priv_a" {
  vpc_id            = data.aws_vpc.vpc.id
  cidr_block        = "10.20.10.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name                              = "${var.prefix}-private-subnet-a"
  }
}
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.prefix}-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = module.vpc.public_subnets[0]

  tags = {
    Name = "${var.prefix}-nat"
  }

  depends_on = [module.vpc]
}

resource "aws_route_table" "priv_a" {
  vpc_id = data.aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.prefix}-private-rt"
  }
}

resource "aws_route_table_association" "priv_a" {
  subnet_id      = aws_subnet.priv_a.id
  route_table_id = aws_route_table.priv_a.id
}