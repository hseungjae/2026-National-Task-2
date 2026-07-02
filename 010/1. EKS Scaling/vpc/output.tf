output "vpc_id" {
  value = data.aws_vpc.vpc.id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = [aws_subnet.priv_a.id, aws_subnet.priv_b.id]
}
