output "topic_arn" {
  value = aws_sns_topic.sensor_alert.arn
}

output "topic_name" {
  value = aws_sns_topic.sensor_alert.name
}
