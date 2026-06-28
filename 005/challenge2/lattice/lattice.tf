resource "aws_security_group" "lattice_hub" {
  name        = "wsc-hub-lattice-sg"
  description = "VPC Lattice security group in Hub VPC"
  vpc_id      = var.hub_vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "wsc-hub-lattice-sg" }
}

resource "aws_vpclattice_service_network" "this" {
  name      = "wsc-app-service-network"
  auth_type = "NONE"

  tags = { Name = "wsc-app-service-network" }
}

resource "aws_vpclattice_service_network_vpc_association" "hub" {
  vpc_identifier             = var.hub_vpc_id
  service_network_identifier = aws_vpclattice_service_network.this.id
  security_group_ids         = [aws_security_group.lattice_hub.id]
}

resource "aws_vpclattice_service_network_vpc_association" "spoke" {
  vpc_identifier             = var.spoke_vpc_id
  service_network_identifier = aws_vpclattice_service_network.this.id
  security_group_ids         = [var.spoke_private_sg_id]
}

resource "aws_vpclattice_target_group" "v1" {
  name = "wsc-spoke-v1-tg"
  type = "ALB"

  config {
    vpc_identifier = var.spoke_vpc_id
    port           = 80
    protocol       = "HTTP"
  }

  tags = { Name = "wsc-spoke-v1-tg" }
}

resource "aws_vpclattice_target_group_attachment" "v1" {
  target_group_identifier = aws_vpclattice_target_group.v1.id
  target {
    id   = var.alb_arn
    port = 80
  }
}

resource "aws_vpclattice_target_group" "v2" {
  name = "wsc-spoke-v2-tg"
  type = "ALB"

  config {
    vpc_identifier = var.spoke_vpc_id
    port           = 80
    protocol       = "HTTP"
  }

  tags = { Name = "wsc-spoke-v2-tg" }
}

resource "aws_vpclattice_target_group_attachment" "v2" {
  target_group_identifier = aws_vpclattice_target_group.v2.id
  target {
    id   = var.alb_arn
    port = 80
  }
}

resource "aws_vpclattice_service" "this" {
  name      = "wsc-app-service"
  auth_type = "NONE"

  tags = { Name = "wsc-app-service" }
}

resource "aws_vpclattice_service_network_service_association" "this" {
  service_identifier         = aws_vpclattice_service.this.id
  service_network_identifier = aws_vpclattice_service_network.this.id
}

resource "aws_vpclattice_listener" "http" {
  name               = "wsc-app-listener"
  protocol           = "HTTP"
  port               = 80
  service_identifier = aws_vpclattice_service.this.id

  default_action {
    forward {
      target_groups {
        target_group_identifier = aws_vpclattice_target_group.v1.id
        weight                  = 90
      }
      target_groups {
        target_group_identifier = aws_vpclattice_target_group.v2.id
        weight                  = 10
      }
    }
  }
}

resource "aws_vpclattice_listener_rule" "v1_header" {
  name                = "version-v1-rule"
  listener_identifier = aws_vpclattice_listener.http.listener_id
  service_identifier  = aws_vpclattice_service.this.id
  priority            = 10

  match {
    http_match {
      header_matches {
        name          = "version"
        case_sensitive = false
        match {
          exact = "v1"
        }
      }
    }
  }

  action {
    forward {
      target_groups {
        target_group_identifier = aws_vpclattice_target_group.v1.id
        weight                  = 100
      }
    }
  }
}

resource "aws_vpclattice_listener_rule" "v2_header" {
  name                = "version-v2-rule"
  listener_identifier = aws_vpclattice_listener.http.listener_id
  service_identifier  = aws_vpclattice_service.this.id
  priority            = 20

  match {
    http_match {
      header_matches {
        name          = "version"
        case_sensitive = false
        match {
          exact = "v2"
        }
      }
    }
  }

  action {
    forward {
      target_groups {
        target_group_identifier = aws_vpclattice_target_group.v2.id
        weight                  = 100
      }
    }
  }
}
