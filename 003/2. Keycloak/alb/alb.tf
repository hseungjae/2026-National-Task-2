resource "aws_lb" "keycloak" {
  name               = "${var.prefix}-keycloak-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.alb_sg
  subnets            = var.subnets
  tags               = { Name = "${var.prefix}-keycloak-alb" }
}



resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.keycloak.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.keycloak.arn
  }
}