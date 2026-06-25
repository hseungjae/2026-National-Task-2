output "kafka_instance_id" {
  value = aws_instance.kafka.id
}

output "kafka_private_ip" {
  value = aws_instance.kafka.private_ip
}

output "kafka_public_ip" {
  value = aws_instance.kafka.public_ip
}
