resource "aws_s3_bucket" "bucket" {
  bucket = "${var.prefix}-landing-ab-${var.account_id}"
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

locals {
  file_map = {
    "index_a.html" = "version-a/index.html"
    "index_b.html" = "version-b/index.html"
  }
}

resource "aws_s3_object" "upload" {
  for_each = local.file_map

  bucket       = aws_s3_bucket.bucket.id
  key          = each.value
  source       = "${path.module}/FILE/${each.key}"
}