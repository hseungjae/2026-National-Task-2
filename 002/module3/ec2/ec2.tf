resource "aws_iam_role" "event_ec2" {
  name = "wsc2026-event-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "wsc2026-event-ec2-role" }
}

resource "aws_iam_role_policy_attachment" "event_ec2_ssm" {
  role       = aws_iam_role.event_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "event_ec2" {
  name = "wsc2026-event-ec2-profile"
  role = aws_iam_role.event_ec2.name
}

resource "aws_security_group" "event_ec2" {
  name        = "wsc2026-event-sg"
  description = "Security group for event EC2 - minimum permissions"
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

  tags = { Name = "wsc2026-event-sg" }
}

resource "aws_instance" "event" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.event_ec2.id]
  iam_instance_profile        = aws_iam_instance_profile.event_ec2.name
  associate_public_ip_address = true

  tags = { Name = "wsc2026-event-ec2", Owner = "wsc2026" }
}
