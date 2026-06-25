variable "lambda_url" {
  description = "Lambda Function URL for the rotate function"
  type        = string
}

variable "request_lambda_arn" {
  description = "Qualified ARN of the viewer-request Lambda@Edge function"
  type        = string
}

variable "response_lambda_arn" {
  description = "Qualified ARN of the origin-response Lambda@Edge function"
  type        = string
}
