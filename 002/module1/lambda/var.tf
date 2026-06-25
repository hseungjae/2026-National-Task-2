variable "lambda_role_arn" {
  type        = string
  description = "IAM role ARN for score function"
}

variable "lambda_trigger_role_arn" {
  type        = string
  description = "IAM role ARN for trigger function"
}

variable "s3_bucket_name" {
  type = string
}

variable "s3_bucket_arn" {
  type = string
}

variable "dynamodb_table_name" {
  type = string
}
