resource "aws_s3_bucket" "sensor_alert" {
  bucket        = "wsc2026-sensor-alert-bucket-${var.contestant_number}"
  force_destroy = true

  tags = { Name = "wsc2026-sensor-alert-bucket-${var.contestant_number}" }
}

resource "aws_s3_object" "producer_binary" {
  bucket = aws_s3_bucket.sensor_alert.id
  key    = "binary/app"
  source = "${path.module}/../scripts/app"
  etag   = filemd5("${path.module}/../scripts/app")
}
