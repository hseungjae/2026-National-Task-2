
resource "tls_private_key" "kafka_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "kafka_key_pair" {
  key_name   = "gj2026-data-key"
  public_key = tls_private_key.kafka_key.public_key_openssh
}

resource "local_file" "kafka_private_key" {
  content         = tls_private_key.kafka_key.private_key_pem
  filename        = "${path.module}/gj2026-data-key.pem"
  file_permission = "0600"
}

resource "aws_security_group" "kafka" {
  name        = "gj2026-data-sg"
  description = "Security group for Kafka EC2"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kafka internal"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kafka external (NLB)"
    from_port   = 9094
    to_port     = 9094
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Flink Web UI"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "gj2026-data-sg" }
}

resource "aws_iam_role" "kafka" {
  name = "gj2026-data-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.kafka.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "kafka" {
  name = "gj2026-data-ec2-profile"
  role = aws_iam_role.kafka.name
}

resource "aws_instance" "kafka" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.kafka.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.kafka.name
  key_name                    = aws_key_pair.kafka_key_pair.key_name

  user_data = base64encode(templatefile("${path.module}/userdata.sh.tpl", {
    scripts_bucket = var.scripts_bucket
  }))

  tags = {
    Name = "gj2026-data-ec2"
  }
}
