variable "server_cert_domain" {
  description = "서버 인증서 도메인 (ACM 에 사전 import 필요)"
  type        = string
  default     = "cve.wsc"
}

variable "client_cert_domain" {
  description = "클라이언트 인증서 도메인 (ACM 에 사전 import 필요)"
  type        = string
  default     = "client.wsc"
}
