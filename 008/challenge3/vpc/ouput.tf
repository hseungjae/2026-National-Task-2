output "vpc_id" {
  value = aws_vpc.ceh.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}
