variable "vpc_id" {
  type = string
}

variable "private_subnet_a_id" {
  type = string
}

variable "public_subnet_a_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "ami_id" {
  type = string
}

variable "instance_profile" {
  type = string
}

variable "msk_sg_id" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}
