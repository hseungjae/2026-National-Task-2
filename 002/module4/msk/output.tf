output "cluster_arn" {
  value = aws_msk_cluster.wsc2026.arn
}

output "msk_sg_id" {
  value = aws_security_group.msk.id
}

output "bootstrap_brokers_iam" {
  value = aws_msk_cluster.wsc2026.bootstrap_brokers_sasl_iam
}

output "bootstrap_brokers_plaintext" {
  value = aws_msk_cluster.wsc2026.bootstrap_brokers
}
