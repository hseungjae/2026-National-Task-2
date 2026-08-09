output "client_vpc_id" {
  value = aws_vpc.client.id
}

output "service_vpc_id" {
  value = aws_vpc.service.id
}

output "client_public_subnet_id" {
  value = aws_subnet.client_public.id
}

output "service_private_subnet_id" {
  value = aws_subnet.service_private.id
}

output "service_public_subnet_id" {
  value = aws_subnet.service_public.id
}
