output "node_role_arn" {
  value = aws_iam_role.node.arn
}

output "node_role_name" {
  value = aws_iam_role.node.name
}

output "ebs_csi_role_arn" {
  value = aws_iam_role.ebs_csi.arn
}

output "bastion_instance_profile_name" {
  value = aws_iam_instance_profile.bastion.name
}

output "bastion_role_arn" {
  value = aws_iam_role.bastion.arn
}
