output "bucket_name" {
  value = aws_s3_bucket.sensor_alert.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.sensor_alert.arn
}
