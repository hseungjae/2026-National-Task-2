variable "subnet_group_name" {
  type = string
}

variable "sg_id" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}
