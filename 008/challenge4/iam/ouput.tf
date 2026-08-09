output "fargate_role_arn" {
  value = aws_iam_role.fargate.arn
}

output "karpenter_role_arn" {
  value = aws_iam_role.karpenter.arn
}

output "keda_role_arn" {
  value = aws_iam_role.keda.arn
}

output "worker_role_arn" {
  value = aws_iam_role.worker.arn
}

output "node_role_arn" {
  value = aws_iam_role.node.arn
}

output "node_role_name" {
  value = aws_iam_role.node.name
}
