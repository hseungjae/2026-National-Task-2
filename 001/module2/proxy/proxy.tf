# ── RDS Proxy IAM Role (Secrets Manager 접근) ────────────────────────────────
resource "aws_iam_role" "proxy_role" {
  name = "wsc2026-rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "rds.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "proxy_policy" {
  name = "secrets-access"
  role = aws_iam_role.proxy_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = var.secret_arn
    }]
  })
}

# ── RDS Proxy (대규모 커넥션 풀링) ───────────────────────────────────────────
resource "aws_db_proxy" "this" {
  name                   = "wsc2026-rds-proxy"
  engine_family          = "MYSQL"
  debug_logging          = false
  idle_client_timeout    = 1800
  require_tls            = false
  role_arn               = aws_iam_role.proxy_role.arn
  vpc_security_group_ids = [var.sg_id]
  vpc_subnet_ids         = var.subnet_ids

  auth {
    auth_scheme = "SECRETS"
    secret_arn  = var.secret_arn
    iam_auth    = "DISABLED"
  }
}

resource "aws_db_proxy_default_target_group" "this" {
  db_proxy_name = aws_db_proxy.this.name
}

resource "aws_db_proxy_target" "this" {
  db_proxy_name          = aws_db_proxy.this.name
  target_group_name      = aws_db_proxy_default_target_group.this.name
  db_instance_identifier = var.db_instance_identifier
}

# ── Secrets Manager 에 Proxy 엔드포인트(host) 반영 ───────────────────────────
# Lambda(lambda_db_client.py)는 secret 의 'host' 필드로 프록시에 접속한다.
resource "aws_secretsmanager_secret_version" "with_proxy_host" {
  secret_id = var.secret_id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    engine   = "mysql"
    dbname   = var.db_name
    host     = aws_db_proxy.this.endpoint
  })

  depends_on = [aws_db_proxy.this]
}
