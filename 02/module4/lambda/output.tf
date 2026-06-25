output "sensor_consumer_arn" {
  value = aws_lambda_function.sensor_consumer.arn
}

output "alert_consumer_arn" {
  value = aws_lambda_function.alert_consumer.arn
}
