output "vpc_id" {
  value = aws_vpc.vpn_vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.vpn_vpc.cidr_block
}

output "vpn_sn_a_id" {
  value = aws_subnet.vpn_sn_a.id
}

output "vpn_sn_b_id" {
  value = aws_subnet.vpn_sn_b.id
}
