resource "aws_dynamodb_table" "orders" {
  name         = "${var.prefix}-orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "order_id"
  range_key    = "ordered_at"

  attribute {
    name = "order_id"
    type = "S"
  }

  attribute {
    name = "ordered_at"
    type = "S"
  }

  tags = { Name = "${var.prefix}-orders" }
}
