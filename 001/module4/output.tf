output "vpc_id" {
  value = module.network.vpc_id
}

output "ec2_instance_id" {
  value = module.ec2.instance_id
}

output "ec2_private_ip" {
  value = module.ec2.private_ip
}

output "vpn_endpoint_id" {
  value = module.vpn.vpn_endpoint_id
}

output "ec2_private_key_pem" {
  value     = tls_private_key.vpn_ec2.private_key_pem
  sensitive = true
}
