variable "region" {
  default = "ap-northeast-1"
}

variable "cluster_name" {
  default = "wsc-logging-cluster"
}

variable "contestant_number" {
  description = "Contestant number for Grafana admin credentials"
  default     = "100"
}
