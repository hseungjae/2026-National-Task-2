resource "aws_secretsmanager_secret" "docdb" {
  name                    = "skills-nosql-docdb-secret"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "docdb" {
  secret_id = aws_secretsmanager_secret.docdb.id

  secret_string = jsonencode({
    username = var.master_username
    password = var.docdb_password
    host     = var.cluster_endpoint
  })
}
