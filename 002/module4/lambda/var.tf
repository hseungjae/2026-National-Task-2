variable "lambda_role_arn" {
  type = string
}

variable "dynamodb_table" {
  type = string
}

variable "alert_topic_arn" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

variable "msk_cluster_arn" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "msk_sg_id" {
  type = string
}
