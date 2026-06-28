resource "aws_security_group" "analytics_ec2" {
  name        = "wsc2026-analytics-ec2-sg"
  description = "Security group for analytics EC2"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["10.20.0.0/16"]
    description = "Allow ALB traffic"
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

  tags = { Name = "wsc2026-analytics-ec2-sg" }
}

resource "aws_instance" "analytics" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_a_id
  vpc_security_group_ids = [aws_security_group.analytics_ec2.id]
  iam_instance_profile   = var.ec2_role_name

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    stream_name = var.kinesis_stream_name
    region      = "ap-northeast-2"
  }))

  tags = { Name = "wsc2026-analytics-ec2" }
}
