output "client_ec2_id" {
  value = aws_instance.lattice_client.id
}

output "service_ec2_id" {
  value = aws_instance.lattice_service.id
}

output "client_sg_id" {
  value = aws_security_group.client_ec2.id
}

output "service_sg_id" {
  value = aws_security_group.service_ec2.id
}
