output "bucket_name" {
  value = aws_s3_bucket.cdn.id
}

output "bucket_arn" {
  value = aws_s3_bucket.cdn.arn
}
