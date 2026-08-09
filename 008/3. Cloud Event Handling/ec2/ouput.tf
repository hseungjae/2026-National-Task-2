output "protected_sg_id" {
  value = aws_security_group.protected.id
}

output "ec2_id" {
  value = aws_instance.ceh.id
}
