resource "aws_vpclattice_service_network" "sn" {
  name      = "skills-lattice-sn"
  auth_type = "NONE"
  tags      = { Name = "skills-lattice-sn" }
}

resource "aws_security_group" "sn_association" {
  name        = "skills-lattice-sn-association-sg"
  description = "VPC Lattice SN association security group"
  vpc_id      = var.client_vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.61.0.0/16"]
    description = "Allow HTTP from Client VPC CIDR"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "skills-lattice-sn-association-sg" }
}

resource "aws_vpclattice_service_network_vpc_association" "client" {
  vpc_identifier             = var.client_vpc_id
  service_network_identifier = aws_vpclattice_service_network.sn.id
  security_group_ids         = [aws_security_group.sn_association.id]
}

resource "aws_vpclattice_target_group" "order" {
  name = "skills-lattice-order-tg"
  type = "INSTANCE"

  config {
    port           = 8080
    protocol       = "HTTP"
    vpc_identifier = var.service_vpc_id

    health_check {
      enabled                   = true
      path                      = "/health"
      protocol                  = "HTTP"
      healthy_threshold_count   = 2
      unhealthy_threshold_count = 2
      matcher {
        value = "200"
      }
    }
  }

  tags = { Name = "skills-lattice-order-tg" }
}

resource "aws_vpclattice_target_group_attachment" "service_ec2" {
  target_group_identifier = aws_vpclattice_target_group.order.id

  target {
    id   = var.service_ec2_id
    port = 8080
  }
}

resource "aws_vpclattice_service" "order" {
  name      = "skills-lattice-order-service"
  auth_type = "NONE"
  tags      = { Name = "skills-lattice-order-service" }
}

resource "aws_vpclattice_listener" "http" {
  name               = "skills-lattice-http-listener"
  service_identifier = aws_vpclattice_service.order.id
  protocol           = "HTTP"
  port               = 80

  default_action {
    forward {
      target_groups {
        target_group_identifier = aws_vpclattice_target_group.order.id
        weight                  = 100
      }
    }
  }

  tags = { Name = "skills-lattice-http-listener" }
}

resource "aws_vpclattice_service_network_service_association" "order" {
  service_identifier         = aws_vpclattice_service.order.id
  service_network_identifier = aws_vpclattice_service_network.sn.id
}
