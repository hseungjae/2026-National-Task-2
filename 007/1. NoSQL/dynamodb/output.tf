output "reserve_ddb_stream_arn" {
  value = aws_dynamodb_table.reservation.stream_arn
}

output "audit_ddb_arn" {
  value = aws_dynamodb_table.audit.arn
}

output "reservation_table_name" {
  value = aws_dynamodb_table.reservation.name
}

output "reservation_table_arn" {
  value = aws_dynamodb_table.reservation.arn
}

output "reservation_gsi_name" {
  value = tolist(aws_dynamodb_table.reservation.global_secondary_index)[0].name
}
