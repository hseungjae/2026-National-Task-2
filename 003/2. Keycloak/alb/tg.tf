resource "aws_lb_target_group" "keycloak" {
  name        = "${var.prefix}-keycloak-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path              = "/"
    matcher           = "200-399"
    interval          = 15
    healthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "keycloak" {
  target_group_arn = aws_lb_target_group.keycloak.arn
  target_id        = var.instance_id
  port             = 8080
}