resource "aws_s3_bucket" "bucket" {
  bucket = "${var.prefix}-cdn-asset-${var.userPin}"
}

resource "aws_s3_bucket_versioning" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "upload" {
  bucket       = aws_s3_bucket.bucket.id
  key          = "origin/worldskills_banner.png"
  source       = "${path.module}/FILE/worldskills_banner.png"
}