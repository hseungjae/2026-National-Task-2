variable "docdb_password" {
  description = "DocumentDB master password"
  type        = string
  default     = "Skills2026!"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}
