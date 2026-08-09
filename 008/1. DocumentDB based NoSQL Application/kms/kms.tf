resource "aws_kms_key" "docdb" {
  description             = "KMS key for DocumentDB encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = { Name = "skills-nosql-docdb-kms" }
}

resource "aws_kms_alias" "docdb" {
  name          = "alias/skills-nosql-docdb"
  target_key_id = aws_kms_key.docdb.key_id
}
