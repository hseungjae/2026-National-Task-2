output "table_arn" {
  value = aws_dynamodb_table.orders.arn
}

output "table_name" {
  value = aws_dynamodb_table.orders.name
}
