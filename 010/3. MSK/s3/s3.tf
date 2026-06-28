# ===== S3 =====
resource "aws_s3_bucket" "orders" {
  bucket = "${var.prefix}-msk-order-data-${var.userPin}-bucket"
}

resource "aws_s3_bucket_public_access_block" "orders" {
  bucket                  = aws_s3_bucket.orders.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

