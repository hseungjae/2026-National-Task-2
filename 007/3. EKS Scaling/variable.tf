variable "region" {
  default = "ap-northeast-2"
}

variable "prefix" {
  default = "skm"
}

variable "awscli_profile" {
  default = "default"
}

variable "karpenter_version" {
  default = "1.13.0"
}

variable "k8s_version" {
  default = "1.35"
}
