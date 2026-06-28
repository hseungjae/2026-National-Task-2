output "vpc_id" {
  value = data.aws_vpc.vpc.id
}

output "private_subnets" {
  value = [aws_subnet.priv_a.id, aws_subnet.priv_c.id]
}
