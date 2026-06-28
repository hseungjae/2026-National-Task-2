resource "aws_security_group" "msk" {
  name        = "wsc-msk-sg"
  description = "msk cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "wsc-msk-sg" }
}

resource "aws_security_group_rule" "msk_from_app" {
  type                     = "ingress"
  from_port                = 9092
  to_port                  = 9092
  protocol                 = "tcp"
  source_security_group_id = var.app_sg_id
  security_group_id        = aws_security_group.msk.id
}



resource "aws_security_group_rule" "msk_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.msk.id
}