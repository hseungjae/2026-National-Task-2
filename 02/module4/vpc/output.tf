output "vpc_id" {
  value = aws_vpc.msk.id
}

output "public_subnet_a_id" {
  value = aws_subnet.pub_a.id
}

output "public_subnet_b_id" {
  value = aws_subnet.pub_b.id
}

output "private_subnet_a_id" {
  value = aws_subnet.priv_a.id
}

output "private_subnet_b_id" {
  value = aws_subnet.priv_b.id
}
