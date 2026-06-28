output "table_name" {
  value = aws_dynamodb_table.api_storage.name
}

output "table_arn" {
  value = aws_dynamodb_table.api_storage.arn
}
