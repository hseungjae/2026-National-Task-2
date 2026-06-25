output "instance_id" {
  value = aws_instance.event.id
}

output "sg_id" {
  value = aws_security_group.event_ec2.id
}

output "ec2_role_name" {
  value = aws_iam_role.event_ec2.name
}
