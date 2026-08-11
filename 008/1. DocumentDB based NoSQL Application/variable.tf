variable "awscli_profile" {
  default = "default"
}

variable "region" {
  default = "ap-northeast-2"
}

variable "docdb_password" {
  description = "DocumentDB master password"
  type        = string
  default     = "Skills2026!"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
