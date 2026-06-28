resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = "t3.medium"
  subnet_id                   = var.pub_subnet[1]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.app.id]
  key_name               = aws_key_pair.ssh.key_name
  iam_instance_profile   = aws_iam_instance_profile.app.name

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y python3.12-pip java-17-amazon-corretto wget tar
    python3.12 -m pip install kafka-python boto3
  EOF

  tags = { Name = "wsc-app-ec2" }
}
