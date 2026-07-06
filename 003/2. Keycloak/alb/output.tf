output "alb_dns" {
  value = aws_lb.keycloak.dns_name
}

output "alb_url" {
  value = "http://${aws_lb.keycloak.dns_name}"
}
