resource "aws_security_group" "producer" {
  name        = "wsc2026-producer-sg"
  description = "Security group for sensor producer EC2"
  vpc_id      = var.vpc_id

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
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/16"]
    description = "MSK plaintext"
  }

  egress {
    from_port   = 9098
    to_port     = 9098
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/16"]
    description = "MSK IAM Auth"
  }

  tags = { Name = "wsc2026-producer-sg" }
}

resource "aws_security_group_rule" "msk_from_producer" {
  type                     = "ingress"
  from_port                = 9098
  to_port                  = 9098
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.producer.id
  security_group_id        = var.msk_sg_id
  description              = "Allow producer to MSK IAM"
}

resource "aws_instance" "producer" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_a_id
  vpc_security_group_ids = [aws_security_group.producer.id]
  iam_instance_profile   = var.instance_profile

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    s3_bucket_name = var.s3_bucket_name
  }))

  tags = { Name = "wsc2026-sensor-producer" }
}
