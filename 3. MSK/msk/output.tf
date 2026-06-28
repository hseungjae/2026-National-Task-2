output "cluster_arn" {
  value = aws_msk_cluster.this.arn
}

output "msk_sg_id" {
  value = aws_security_group.msk.id
}
