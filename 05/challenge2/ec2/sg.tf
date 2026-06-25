resource "aws_security_group" "bastion" {
  name        = "wsc-hub-bastion-sg"
  description = "Bastion security group - SSH only"
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

  tags = { Name = "wsc-hub-bastion-sg" }
}

resource "aws_security_group" "app" {
  name        = "wsc-spoke-app-sg"
  description = "App server security group"
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

  tags = { Name = "wsc-spoke-app-sg" }
}
