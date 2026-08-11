variable "awscli_profile" {
  default = "default"
}

variable "region" {
  default = "ap-southeast-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.nano"
}
