resource "aws_dynamodb_table" "ddb" {
  name         = "${var.prefix}-worldschool-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "admission_year"
  range_key    = "student_name"

  attribute {
    name = "admission_year"
    type = "N"
  }

  attribute {
    name = "student_name"
    type = "S"
  }

  deletion_protection_enabled = true

  tags = { Name = "${var.prefix}-worldschool-table" }
}