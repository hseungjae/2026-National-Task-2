output "ecr_repository_url" {
  value = module.ecr.repository_url
}

# 아래 두 출력은 module.app / module.grafana 가 활성화(주석 해제)된 뒤에 함께 주석 해제한다.
output "app_alb_dns_name" {
  value = module.app.alb_dns_name
}

output "grafana_alb_dns_name" {
  value = module.grafana.alb_dns_name
}
