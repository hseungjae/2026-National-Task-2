resource "aws_dynamodb_table" "orders" {
  name         = "order-records"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "orderId"
  range_key    = "timestamp"

  attribute {
    name = "orderId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  tags = { Name = "order-records" }
}