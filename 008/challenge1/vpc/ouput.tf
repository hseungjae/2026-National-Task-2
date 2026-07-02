output "vpc_id" {
  value = aws_vpc.nosql.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_a_id" {
  value = aws_subnet.private_a.id
}

output "private_subnet_b_id" {
  value = aws_subnet.private_b.id
}

output "client_sg_id" {
  value = aws_security_group.client_ec2.id
}

output "docdb_sg_id" {
  value = aws_security_group.docdb.id
}
