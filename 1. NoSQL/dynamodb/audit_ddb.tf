resource "aws_dynamodb_table" "audit" {
  name         = "${var.prefix}-audit-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"


  attribute {
    name = "event_id"
    type = "S"
  }
}