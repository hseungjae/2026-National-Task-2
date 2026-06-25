variable "function_name" {
  type = string
}

variable "secret_name" {
  type = string
}

variable "secret_arn" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "sg_id" {
  type = string
}
