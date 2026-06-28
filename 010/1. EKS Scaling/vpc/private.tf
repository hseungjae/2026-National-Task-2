resource "aws_subnet" "priv_a" {
  vpc_id            = data.aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name                              = "${var.prefix}-priv-a"
    "karpenter.sh/discovery"= "${var.prefix}-eks"
  }
}

resource "aws_subnet" "priv_b" {
  vpc_id            = data.aws_vpc.vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.region}b"

  tags = {
    Name                              = "${var.prefix}-priv-b"
    "karpenter.sh/discovery"= "${var.prefix}-eks"
  }
}

resource "aws_eip" "nat_a" {
  domain = "vpc"

  tags = {
    Name = "${var.prefix}-eip"
  }
}

resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
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
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = {
    Name = "${var.prefix}-skills-priv-rt-a"
  }
}

resource "aws_route_table" "priv_b" {
  vpc_id = data.aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = {
    Name = "${var.prefix}-skills-priv-rt-b"
  }
}

resource "aws_route_table_association" "priv_a" {
  subnet_id      = aws_subnet.priv_a.id
  route_table_id = aws_route_table.priv_a.id
}

resource "aws_route_table_association" "priv_b" {
  subnet_id      = aws_subnet.priv_b.id
  route_table_id = aws_route_table.priv_b.id
}
