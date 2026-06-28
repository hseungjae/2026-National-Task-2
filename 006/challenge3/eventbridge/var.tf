variable "lambda_arn" {
  description = "Recovery Lambda function ARN"
  type        = string
}

variable "lambda_function_name" {
  description = "Recovery Lambda function name"
  type        = string
}

variable "alarm_name" {
  description = "CloudWatch Alarm name"
  type        = string
}
