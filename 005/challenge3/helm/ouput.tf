output "loki_release_name" {
  value = helm_release.loki.name
}

output "grafana_release_name" {
  value = helm_release.grafana.name
}
