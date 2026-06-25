resource "aws_security_group" "alb" {
  name        = "wsc-spoke-app-alb-sg"
  description = "ALB security group"
  vpc_id      = var.spoke_vpc_id

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

  tags = { Name = "wsc-spoke-app-alb-sg" }
}

resource "aws_lb_target_group" "v1" {
  name        = "wsc-spoke-v1-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.spoke_vpc_id
  target_type = "instance"

  health_check {
    path                = "/healthcheck"
    protocol            = "HTTP"
    port                = "8080"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
    matcher             = "200"
  }

  tags = { Name = "wsc-spoke-v1-tg" }
}

resource "aws_lb_target_group" "v2" {
  name        = "wsc-spoke-v2-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.spoke_vpc_id
  target_type = "instance"

  health_check {
    path                = "/healthcheck"
    protocol            = "HTTP"
    port                = "8080"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
    matcher             = "200"
  }

  tags = { Name = "wsc-spoke-v2-tg" }
}

resource "aws_lb_target_group_attachment" "v1" {
  target_group_arn = aws_lb_target_group.v1.arn
  target_id        = var.app_v1_id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "v2" {
  target_group_arn = aws_lb_target_group.v2.arn
  target_id        = var.app_v2_id
  port             = 8080
}

resource "aws_lb" "this" {
  name               = "wsc-spoke-app-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [var.spoke_private_subnet_a_id, var.spoke_private_subnet_c_id]

  tags = { Name = "wsc-spoke-app-alb" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.v1.arn
        weight = 90
      }
      target_group {
        arn    = aws_lb_target_group.v2.arn
        weight = 10
      }
    }
  }
}

resource "aws_lb_listener_rule" "healthcheck_restrict" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1

  condition {
    path_pattern {
      values = ["/healthcheck"]
    }
  }

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Restrict access to api"
      status_code  = "403"
    }
  }
}

resource "aws_lb_listener_rule" "version_v1" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  condition {
    http_header {
      http_header_name = "version"
      values           = ["v1"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.v1.arn
  }
}

resource "aws_lb_listener_rule" "version_v2" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  condition {
    http_header {
      http_header_name = "version"
      values           = ["v2"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.v2.arn
  }
}
