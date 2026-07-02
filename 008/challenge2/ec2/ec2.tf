resource "aws_instance" "lattice_client" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.client_public_subnet_id
  vpc_security_group_ids      = [aws_security_group.client_ec2.id]
  iam_instance_profile        = var.instance_profile_name
  associate_public_ip_address = true
  user_data                   = file("${path.module}/../../../challenge2/client/user_data.sh")

  tags = {
    Name = "skills-lattice-client-ec2"
  }
}

resource "aws_instance" "lattice_service" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.service_private_subnet_id
  vpc_security_group_ids      = [aws_security_group.service_ec2.id]
  associate_public_ip_address = false
  user_data                   = file("${path.module}/../../../challenge2/service/user_data.sh")

  tags = {
    Name = "skills-lattice-service-ec2"
  }
}
