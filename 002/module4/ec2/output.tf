output "instance_id" {
  value = aws_instance.producer.id
}

output "producer_sg_id" {
  value = aws_security_group.producer.id
}
