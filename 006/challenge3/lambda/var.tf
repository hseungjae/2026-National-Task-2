variable "recovery_role_arn" {
  description = "IAM role ARN for recovery Lambda"
  type        = string
}

variable "updater_role_arn" {
  description = "IAM role ARN for updater Lambda"
  type        = string
}

variable "instance_id" {
  description = "EC2 instance ID"
  type        = string
}
