variable "vpc_id" {
  type = string
}

variable "private_subnet_a_id" {
  type = string
}

variable "public_subnet_a_id" {
  type = string
}

variable "ec2_role_name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "ami_id" {
  type = string
}

variable "kinesis_stream_name" {
  type = string
}
