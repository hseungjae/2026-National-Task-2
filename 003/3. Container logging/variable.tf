variable "region" {
  default = "ap-northeast-1"
}

variable "awscli_profile" {
  default = "default"
}

variable "prefix" {
  default = "wsc2026"
}

variable "grafana_admin_password" {
  default   = "Skill53@@"
  sensitive = true
}
