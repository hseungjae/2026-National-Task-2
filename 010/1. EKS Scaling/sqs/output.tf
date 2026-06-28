output "queue_url" {
  value = aws_sqs_queue.sqs.url
}

output "queue_arn" {
  value = aws_sqs_queue.sqs.arn
}
