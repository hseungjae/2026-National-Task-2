output "instance_id" {
  value = aws_instance.vpn_ec2.id
}

output "private_ip" {
  value = aws_instance.vpn_ec2.private_ip
}
