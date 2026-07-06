resource "aws_dynamodb_table" "history" {
  name         = "${var.prefix}-pipeline-history"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "execution_id"
  range_key    = "started_at"

  attribute {
    name = "execution_id"
    type = "S"
  }

  attribute {
    name = "started_at"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = { Name = "${var.prefix}-pipeline-history" }
}
