output "stream_name" {
  value = aws_kinesis_stream.order_stream.name
}

output "stream_arn" {
  value = aws_kinesis_stream.order_stream.arn
}
