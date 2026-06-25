output "instance_id" {
  value = aws_instance.event.id
}

output "public_ip" {
  value = aws_instance.event.public_ip
}

output "private_ip" {
  value = aws_instance.event.private_ip
}
