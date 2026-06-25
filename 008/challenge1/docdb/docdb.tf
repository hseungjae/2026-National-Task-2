resource "aws_docdb_subnet_group" "this" {
  name       = "skills-nosql-docdb-subnet-group"
  subnet_ids = [var.private_subnet_a_id, var.private_subnet_b_id]
}

resource "aws_docdb_cluster" "this" {
  cluster_identifier      = "skills-nosql-docdb-cluster"
  engine                  = "docdb"
  master_username         = "docdbadmin"
  master_password         = var.docdb_password
  db_subnet_group_name    = aws_docdb_subnet_group.this.name
  vpc_security_group_ids  = [var.docdb_sg_id]
  kms_key_id              = var.kms_key_arn
  storage_encrypted       = true
  backup_retention_period = 1
  skip_final_snapshot     = true
}

resource "aws_docdb_cluster_instance" "this" {
  identifier         = "skills-nosql-docdb-instance-1"
  cluster_identifier = aws_docdb_cluster.this.id
  instance_class     = "db.t3.medium"
}
