output "vpc_id" {
  value = aws_default_vpc.vpc.id
}

output "subnet_ids" {
  value = [for s in data.aws_subnet.default : s.id]
}
