output "table_name" {
  value = aws_dynamodb_table.target_db.name
}

output "table_arn" {
  value = aws_dynamodb_table.target_db.arn
}
