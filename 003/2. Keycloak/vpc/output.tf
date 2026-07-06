output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnet" {
  value = aws_subnet.priv_a.id
}

output "keycloak_sg" {
  value = [aws_security_group.keycloak.id]
}

output "alb_sg" {
  value = [aws_security_group.alb.id]
}

output "vpc_id" {
  value = data.aws_vpc.vpc.id
}
