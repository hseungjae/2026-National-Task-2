resource "aws_instance" "ceh" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.protected.id]
  associate_public_ip_address = true

  tags = {
    Name = "skills-ceh-ec2"
  }
}
