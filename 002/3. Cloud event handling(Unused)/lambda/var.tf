variable "lambda_role_arn" {
  type = string
}

variable "topic_arn" {
  type = string
}

variable "sg_id" {
  type = string
}

variable "instance_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
