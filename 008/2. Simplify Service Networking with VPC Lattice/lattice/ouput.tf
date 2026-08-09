output "service_domain" {
  value = aws_vpclattice_service.order.dns_entry[0].domain_name
}

output "service_arn" {
  value = aws_vpclattice_service.order.arn
}
