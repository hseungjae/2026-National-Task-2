output "orders_table_arn" {
  value = aws_dynamodb_table.orders.arn
}

output "inventory_table_arn" {
  value = aws_dynamodb_table.inventory.arn
}

output "history_table_arn" {
  value = aws_dynamodb_table.history.arn
}
