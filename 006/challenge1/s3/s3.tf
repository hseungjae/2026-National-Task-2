resource "aws_s3_bucket" "cdn" {
  bucket        = "gj2026-cdn-bucket-${var.beonho}"
  force_destroy = true

  tags = { Name = "gj2026-cdn" }
}

resource "aws_s3_bucket_public_access_block" "cdn" {
  bucket = aws_s3_bucket.cdn.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "dog" {
  bucket       = aws_s3_bucket.cdn.id
  key          = "images/dog.png"
  source       = "${path.root}/../배포파일/CDN/dog.png"
  content_type = "image/png"

  etag = filemd5("${path.root}/../배포파일/CDN/dog.png")
}
