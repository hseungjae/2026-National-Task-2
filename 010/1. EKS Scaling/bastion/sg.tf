resource "aws_security_group" "bastion_sg" {
  name        = "${var.prefix}-bastion-sg"
  vpc_id      = var.vpc_id
  description = "Security Group for bastion"

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }


  tags = {
    "Name" = "${var.prefix}-bastion-sg"
  }
}
