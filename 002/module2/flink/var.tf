variable "flink_role_arn" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "kinesis_stream_arn" {
  type = string
}
