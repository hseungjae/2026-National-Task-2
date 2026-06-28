resource "aws_instance" "bastion" {
  ami           = var.al2023_ami
  instance_type = "t3.small"

  subnet_id              = var.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion_profile.name
  key_name               = aws_key_pair.bastion.key_name

  user_data = <<-EOF
#!/bin/bash

# kubectl install
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

EOF

  tags = {
    "Name" = "${var.prefix}-bastion"
  }
}

resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion.id

  tags = {
    Name = "${var.prefix}-bastion-eip"
  }
}

