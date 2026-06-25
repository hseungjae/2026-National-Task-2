output "db_identifier" {
  value = aws_db_instance.rds.identifier
}

output "db_arn" {
  value = aws_db_instance.rds.arn
}

output "endpoint" {
  value = aws_db_instance.rds.endpoint
}
