output "instance_id" {
  value = aws_instance.keycloak.id
}

output "public_ip" {
  value = aws_eip.keycloak.public_ip
}

output "keycloak_domain" {
  value = "${aws_eip.keycloak.public_ip}.nip.io"
}
