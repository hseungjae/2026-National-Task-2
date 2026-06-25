# Amazon RDS (MySQL 8.4.9, t3.micro, 샌드박스 템플릿 = Multi-AZ/백업 최소)
# - 외부 퍼블릭 액세스 차단, 프라이빗 서브넷 그룹에 배치
resource "aws_db_instance" "rds" {
  identifier     = "wsc2026-rds-instance"
  engine         = "mysql"
  engine_version = "8.4.9"
  instance_class = "db.t3.micro"

  db_name           = "wsc2026"
  allocated_storage = 20
  username          = var.db_username
  password          = var.db_password

  db_subnet_group_name   = var.subnet_group_name
  vpc_security_group_ids = [var.sg_id]
  publicly_accessible    = false

  multi_az                = false
  backup_retention_period = 0
  skip_final_snapshot     = true

  tags = { Name = "wsc2026-rds-instance" }
}
