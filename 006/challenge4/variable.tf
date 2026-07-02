variable "beonho" {
  description = "Competition number (수험번호)"
  type        = string
  default     = "01"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
  default     = ""
}

variable "keycloak_admin_password" {
  description = "Keycloak admin password"
  type        = string
  default     = "admin1234!"
  sensitive   = true
}
