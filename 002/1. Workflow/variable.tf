variable "region" {
  default = "ap-southeast-1"
}

variable "awscli_profile" {
  default = "default"
}

variable "contestant_number" {
  description = "Contestant number (비번호)"
  type        = string
  default     = "105"
}

