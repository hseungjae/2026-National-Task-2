# DB 마스터 자격증명을 보관하는 Secrets Manager 시크릿
# host(프록시 엔드포인트)는 프록시 생성 후 proxy 모듈에서 업데이트한다.
resource "aws_secretsmanager_secret" "db_secret" {
  name        = "wsc2026-db-secret"
  description = "wsc2026 RDS credentials"
}

resource "aws_secretsmanager_secret_version" "initial" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    engine   = "mysql"
    dbname   = var.db_name
  })
}
