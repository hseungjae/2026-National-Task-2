resource "helm_release" "loki" {
  name       = "wsc2026-loki"
  repository = "https://grafana-community.github.io/helm-charts"
  chart      = "loki"
  namespace  = "wsc2026-logging"

  values = [file("${path.module}/values.yaml")]
}
