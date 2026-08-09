output "cluster_endpoint" {
  value = aws_docdb_cluster.this.endpoint
}

output "master_username" {
  value = aws_docdb_cluster.this.master_username
}
