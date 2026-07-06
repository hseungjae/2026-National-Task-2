resource "aws_instance" "keycloak" {
  ami                    = var.al2023_ami
  instance_type          = "t3.medium"
  subnet_id              = var.private_subnet
  vpc_security_group_ids = var.keycloak_sg
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  user_data = templatefile("${path.module}/file/user_data.sh", {
    admin_password = var.keycloak_admin_password
  })

  tags = { Name = "${var.prefix}-keycloak" }

  depends_on = [
    aws_iam_role_policy_attachment.ssm,
    aws_iam_instance_profile.ec2,
  ]
}
