data "aws_secretsmanager_secret_version" "rds_managed" {
  secret_id = var.rds_secret_arn
}

resource "aws_secretsmanager_secret" "aurora_admin" {
  name                    = "rds/aurora/admin"
  recovery_window_in_days = 0

  tags = {
    Module = "RDSConnection"
  }
}

resource "aws_secretsmanager_secret_version" "aurora_admin" {
  secret_id = aws_secretsmanager_secret.aurora_admin.id

  secret_string = jsonencode({
    username = "admin"
    password = jsondecode(data.aws_secretsmanager_secret_version.rds_managed.secret_string)["password"]
  })
}
