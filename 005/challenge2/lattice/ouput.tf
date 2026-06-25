output "service_network_id" {
  value = aws_vpclattice_service_network.this.id
}

output "service_id" {
  value = aws_vpclattice_service.this.id
}

output "service_dns_name" {
  value = aws_vpclattice_service.this.dns_entry
}
