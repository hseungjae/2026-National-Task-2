variable "instance_type" {
  description = "EC2 instance type for sensor producer"
  type        = string
  default     = "t3.small"
}

variable "contestant_number" {
  description = "Contestant number (비번호)"
  type        = string
  default     = "100"
}
