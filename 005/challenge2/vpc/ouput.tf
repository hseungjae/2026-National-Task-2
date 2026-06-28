output "hub_vpc_id" {
  value = aws_vpc.hub.id
}

output "hub_public_subnet_a_id" {
  value = aws_subnet.hub_public_a.id
}

output "hub_public_subnet_c_id" {
  value = aws_subnet.hub_public_c.id
}

output "spoke_vpc_id" {
  value = aws_vpc.spoke.id
}

output "spoke_public_subnet_a_id" {
  value = aws_subnet.spoke_public_a.id
}

output "spoke_private_subnet_a_id" {
  value = aws_subnet.spoke_private_a.id
}

output "spoke_private_subnet_c_id" {
  value = aws_subnet.spoke_private_c.id
}
