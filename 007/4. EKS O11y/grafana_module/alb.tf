resource "aws_security_group" "alb" {
  name        = "${var.prefix}-grafana-alb-sg"
  description = "SG for ${var.prefix}-grafana-alb"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-grafana-alb-sg"
  }
}

resource "aws_lb" "grafana" {
  name               = "${var.prefix}-grafana-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids
}

resource "aws_lb_target_group" "grafana" {
  name        = "${var.prefix}-grafana-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/api/health"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
    matcher             = "200"
  }
}

resource "aws_lb_listener" "grafana" {
  load_balancer_arn = aws_lb.grafana.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }
}
