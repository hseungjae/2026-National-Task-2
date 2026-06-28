output "cluster_arn" {
  value = aws_rds_cluster.aurora.arn
}

output "secret_arn" {
  value = aws_rds_cluster.aurora.master_user_secret[0].secret_arn
}
