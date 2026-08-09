output "vpc_id" {
  value = aws_default_vpc.vpc.id
}

output "subnet_ids" {
  value = data.aws_subnets.default.ids
}
