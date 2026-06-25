variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  default     = "Wsc2026Pass!"
  sensitive   = true
}

variable "function_name" {
  description = "DB client Lambda function name"
  type        = string
  default     = "wsc2026-db-client"
}
