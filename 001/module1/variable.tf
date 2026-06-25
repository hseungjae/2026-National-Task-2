variable "table_name" {
  description = "DynamoDB table name"
  type        = string
  default     = "wsc2026-api-storage"
}

variable "function_name" {
  description = "Lambda function name"
  type        = string
  default     = "wsc2026-api-handler"
}

variable "api_name" {
  description = "REST API name"
  type        = string
  default     = "wsc2026-rest-api"
}

variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "V1"
}
