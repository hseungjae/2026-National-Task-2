output "vpc_id" {
  value = aws_vpc.event.id
}

output "public_subnet_a_id" {
  value = aws_subnet.pub_a.id
}

output "public_subnet_b_id" {
  value = aws_subnet.pub_b.id
}
