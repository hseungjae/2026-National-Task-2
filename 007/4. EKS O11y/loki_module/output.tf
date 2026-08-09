output "namespace" {
  value = kubernetes_namespace.monitoring.metadata[0].name
}

# 클러스터 내부에서 접근할 Loki base URL
output "loki_url" {
  value = "http://${var.loki_release_name}.${kubernetes_namespace.monitoring.metadata[0].name}.svc.cluster.local:3100"
}
