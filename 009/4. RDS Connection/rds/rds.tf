resource "aws_db_subnet_group" "aurora" {
  name       = "rds-aurora-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier = "rds-aurora-cluster"

  engine         = "aurora-mysql"
  engine_version = "8.0.mysql_aurora.3.10.3"

  database_name   = "appdb"
  master_username = "admin"

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 4
  }

  enable_http_endpoint    = true
  skip_final_snapshot     = true

  tags = {
    Module = "RDSConnection"
  }
}

resource "aws_rds_cluster_instance" "aurora" {
  identifier         = "rds-aurora-instance-1"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora.engine
}