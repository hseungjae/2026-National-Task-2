output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "sqs_queue_url" {
  value = module.sqs.queue_url
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "worker_role_arn" {
  value = module.iam.worker_role_arn
}

output "node_role_name" {
  value = module.iam.node_role_name
}

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --name ${aws_eks_cluster.this.name} --region ${var.region}"
}
