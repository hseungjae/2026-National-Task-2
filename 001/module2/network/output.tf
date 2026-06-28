output "vpc_id" {
  value = aws_vpc.db_vpc.id
}

output "db_subnet_ids" {
  value = [aws_subnet.db_sn_a.id, aws_subnet.db_sn_c.id]
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.this.name
}
