data "aws_ec2_managed_prefix_list" "vpc_lattice" {
  filter {
    name   = "prefix-list-name"
    values = ["com.amazonaws.ap-northeast-1.vpc-lattice"]
  }
}

resource "aws_security_group" "client_ec2" {
  name        = "skills-lattice-client-sg"
  description = "Client EC2 security group"
  vpc_id      = var.client_vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
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

  tags = { Name = "skills-lattice-client-sg" }
}

resource "aws_security_group" "service_ec2" {
  name        = "skills-lattice-service-sg"
  description = "Service EC2 security group - VPC Lattice only"
  vpc_id      = var.service_vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.vpc_lattice.id]
    description     = "Allow from VPC Lattice only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "skills-lattice-service-sg" }
}
