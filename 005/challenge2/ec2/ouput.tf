output "app_v1_id" {
  value = aws_instance.app_v1.id
}

output "app_v2_id" {
  value = aws_instance.app_v2.id
}

output "app_v1_private_ip" {
  value = aws_instance.app_v1.private_ip
}

output "app_v2_private_ip" {
  value = aws_instance.app_v2.private_ip
}

output "app_sg_id" {
  value = aws_security_group.app.id
}

output "bastion_public_ip" {
  value = aws_eip.bastion.public_ip
}
