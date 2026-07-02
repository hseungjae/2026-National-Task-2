resource "aws_dynamodb_table" "this" {
  name         = "wsc-rest-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "name"

  attribute {
    name = "name"
    type = "S"
  }

  tags = { Name = "wsc-rest-table" }
}
