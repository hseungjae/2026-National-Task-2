resource "aws_security_group" "protected" {
  name        = "skills-ceh-protected-sg"
  description = "Protected security group - inbound rules will be auto-remediated"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "skills-ceh-protected-sg" }
}
