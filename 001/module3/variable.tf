variable "bucket_name" {
  description = "Inbound S3 bucket name"
  type        = string
  default     = "wsc2026-wf-inbound-bucket"
}

variable "table_name" {
  description = "Target DynamoDB table name"
  type        = string
  default     = "wsc2026-target-db"
}

variable "transform_function_name" {
  description = "Transform Lambda function name"
  type        = string
  default     = "wsc2026-transform-lambda"
}

variable "rule_name" {
  description = "EventBridge rule name"
  type        = string
  default     = "wsc2026-s3-trigger-rule"
}

variable "state_machine_name" {
  description = "Step Functions state machine name"
  type        = string
  default     = "wsc2026-workflow-sf"
}
