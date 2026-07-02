resource "aws_dynamodb_table" "dynamodb" {
  name         = "nosql-products"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "product_id"
  range_key = "category"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"


  attribute {
    name = "product_id"
    type = "S"
  }

  attribute {
    name = "category"
    type = "S"
  }

  attribute {
    name = "price"
    type = "N"
  }


  global_secondary_index {
    name            = "category-price-index"
    hash_key        = "category"
    range_key       = "price"
    projection_type = "ALL"
  }
  tags = {
    Name        = "Module"
    Environment = "NoSQL"
  }
}