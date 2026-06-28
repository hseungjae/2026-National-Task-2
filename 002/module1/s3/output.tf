output "bucket_name" {
  value = aws_s3_bucket.student_score.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.student_score.arn
}
