variable "region" {
  default = "eu-west-1"
}

variable "awscli_profile" {
  default = "default"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}