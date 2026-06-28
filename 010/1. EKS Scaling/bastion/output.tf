output "bastion_role_arn" {
  value = aws_iam_role.bastion_role.arn
}

output "bastion_sg_id" {
  value = aws_security_group.bastion_sg.id
}