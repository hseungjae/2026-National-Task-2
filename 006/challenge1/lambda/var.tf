variable "role_arn" {
  description = "IAM role ARN for Lambda functions"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name for CDN images"
  type        = string
}
