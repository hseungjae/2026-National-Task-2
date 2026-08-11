resource "aws_dynamodb_table" "sensor_data" {
  name         = "wsc2026-sensor-data"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "sensorId"
  range_key    = "timestamp"

  attribute {
    name = "sensorId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  tags = { Name = "wsc2026-sensor-data" }
}
