output "bucket_name" {
  value      = aws_s3_bucket.cloudtrail.id
  depends_on = [aws_s3_bucket_policy.cloudtrail]
}
