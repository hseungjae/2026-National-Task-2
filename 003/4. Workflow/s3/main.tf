resource "aws_s3_bucket" "pipeline" {
  bucket = "${var.prefix}-order-pipeline"

  tags = { Name = "${var.prefix}-order-pipeline" }
}

resource "aws_s3_bucket_versioning" "pipeline" {
  bucket = aws_s3_bucket.pipeline.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "sample_orders" {
  bucket = aws_s3_bucket.pipeline.id
  key    = "incoming/sample-orders.json"
  source = "${path.module}/FILE/sample-orders.json"
}
