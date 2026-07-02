resource "aws_instance" "ec2" {
  ami           = var.al2023_ami
  instance_type = "t3.small"

  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = aws_key_pair.ec2_key.key_name

  user_data = templatefile("${path.module}/app/userdata.sh.tpl", {
    app_py       = file("${path.module}/app/app.py")
    requirements = file("${path.module}/app/requirements.txt")
    table_name   = var.table_name
    aws_region   = var.region
    gsi_name     = var.gsi_name
  })

  tags = {
    "Name" = "${var.prefix}-app-ec2"
  }
}

resource "aws_eip" "ec2_eip" {
  instance = aws_instance.ec2.id

  tags = {
    Name = "${var.prefix}-app-ec2-eip"
  }
}