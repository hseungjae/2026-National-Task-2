output "bucket_name" {
  value = aws_s3_bucket.inbound.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.inbound.arn
}
