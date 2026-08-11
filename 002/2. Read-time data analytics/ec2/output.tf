output "instance_id" {
  value = aws_instance.analytics.id
}

output "ec2_sg_id" {
  value = aws_security_group.analytics_ec2.id
}
