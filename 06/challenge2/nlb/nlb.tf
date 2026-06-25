resource "aws_lb" "kafka" {
  name               = "gj2026-data-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [var.subnet_id]

  enable_deletion_protection = false

  tags = { Name = "gj2026-data-nlb" }
}

resource "aws_lb_target_group" "kafka_external" {
  name        = "gj2026-kafka-tg"
  port        = 9094
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = "9094"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = { Name = "gj2026-kafka-tg" }
}

resource "aws_lb_target_group_attachment" "kafka" {
  target_group_arn = aws_lb_target_group.kafka_external.arn
  target_id        = var.kafka_instance_id
  port             = 9094
}

resource "aws_lb_listener" "kafka_external" {
  load_balancer_arn = aws_lb.kafka.arn
  port              = 9094
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kafka_external.arn
  }
}
