output "node_role_arn" {
  value = aws_iam_role.node.arn
}

output "node_role_name" {
  value = aws_iam_role.node.name
}

output "karpenter_role_arn" {
  value = aws_iam_role.karpenter.arn
}

output "keda_role_arn" {
  value = aws_iam_role.keda.arn
}

output "bastion_instance_profile_name" {
  value = aws_iam_instance_profile.bastion.name
}

output "bastion_role_arn" {
  value = aws_iam_role.bastion.arn
}
