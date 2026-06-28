resource "aws_subnet" "priv_a" {
  vpc_id            = data.aws_vpc.vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name                              = "${var.prefix}-logging-private-subnet-a"
  }
}

resource "aws_subnet" "priv_c" {
  vpc_id            = data.aws_vpc.vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.region}c"

  tags = {
    Name                              = "${var.prefix}-logging-private-subnet-c"
  }
}

resource "aws_eip" "nat_a" {
  domain = "vpc"

  tags = {
    Name = "${var.prefix}-eip-a"
  }
}

resource "aws_eip" "nat_c" {
  domain = "vpc"

  tags = {
    Name = "${var.prefix}-eip-c"
  }
}

resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = module.vpc.public_subnets[0]

  tags = {
    Name = "${var.prefix}-logging-natgateway-a"
  }

  depends_on = [module.vpc]
}

resource "aws_nat_gateway" "nat_c" {
  allocation_id = aws_eip.nat_c.id
  subnet_id     = module.vpc.public_subnets[1]

  tags = {
    Name = "${var.prefix}-logging-natgateway-c"
  }

  depends_on = [module.vpc]
}

resource "aws_route_table" "priv_a" {
  vpc_id = data.aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = {
    Name = "${var.prefix}-logging-private-routing-table-a"
  }
}

resource "aws_route_table" "priv_c" {
  vpc_id = data.aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_c.id
  }

  tags = {
    Name = "${var.prefix}-logging-private-routing-table-c"
  }
}

resource "aws_route_table_association" "priv_a" {
  subnet_id      = aws_subnet.priv_a.id
  route_table_id = aws_route_table.priv_a.id
}

resource "aws_route_table_association" "priv_c" {
  subnet_id      = aws_subnet.priv_c.id
  route_table_id = aws_route_table.priv_c.id
}
