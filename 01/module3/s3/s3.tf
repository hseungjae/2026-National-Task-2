# 데이터 인입 원천 S3 버킷 + EventBridge 알림 활성화
resource "aws_s3_bucket" "inbound" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_notification" "this" {
  bucket      = aws_s3_bucket.inbound.id
  eventbridge = true
}
