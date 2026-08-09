resource "aws_security_group" "alb" {
  name        = "wsc2026-analytics-alb-sg"
  description = "Security group for analytics ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["10.20.0.0/16"]
  }

  tags = { Name = "wsc2026-analytics-alb-sg" }
}

resource "aws_security_group_rule" "ec2_from_alb" {
  type                     = "ingress"
  from_port                = 5000
  to_port                  = 5000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = var.ec2_sg_id
}

resource "aws_lb" "analytics" {
  name               = "wsc2026-analytics-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [var.public_subnet_a_id, var.public_subnet_b_id]

  tags = { Name = "wsc2026-analytics-alb" }
}

resource "aws_lb_target_group" "analytics" {
  name        = "wsc2026-analytics-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    port                = "5000"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = { Name = "wsc2026-analytics-tg" }
}

resource "aws_lb_target_group_attachment" "analytics" {
  target_group_arn = aws_lb_target_group.analytics.arn
  target_id        = var.ec2_instance_id
  port             = 5000
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.analytics.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.analytics.arn
  }
}
