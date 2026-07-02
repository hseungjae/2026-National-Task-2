resource "aws_dynamodb_table" "reservation" {
  name             = "${var.prefix}-reservation-table"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "train_id"
  range_key        = "seat_id"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"


  attribute {
    name = "train_id"
    type = "S"
  }

  attribute {
    name = "seat_id"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "reserved_at"
    type = "S"
  }



  global_secondary_index {
    name            = "gsi-user-reservations"
    hash_key        = "user_id"
    range_key       = "reserved_at"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }
}
