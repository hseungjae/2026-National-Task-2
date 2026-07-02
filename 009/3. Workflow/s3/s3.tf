resource "aws_s3_bucket" "bucket" {
  bucket = "workflow-input-${var.prefix}"

  tags = {
    Name        = "Module"
    Environment = "Workflow"
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
  for_each = fileset("${path.module}/FILE", "*")

  bucket = aws_s3_bucket.bucket.id
  key    = each.value
  source = "${path.module}/FILE/${each.value}"
}
