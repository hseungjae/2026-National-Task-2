output "secret_arn" {
  value = aws_secretsmanager_secret.aurora_admin.arn
}
