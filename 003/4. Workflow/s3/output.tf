output "bucket_name" {
  value = aws_s3_bucket.pipeline.id
}

output "bucket_arn" {
  value = aws_s3_bucket.pipeline.arn
}
