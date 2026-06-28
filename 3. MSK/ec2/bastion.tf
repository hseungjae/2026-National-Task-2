resource "aws_instance" "bastion" {
  ami                    = var.ami_id
  instance_type          = "t3.small"
  subnet_id                   = var.pub_subnet[1]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name               = aws_key_pair.ssh.key_name
  iam_instance_profile   = aws_iam_instance_profile.bastion.name

  tags = { Name = "wsc-bastion-ec2" }
}