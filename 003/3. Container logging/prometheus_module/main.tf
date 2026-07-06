resource "helm_release" "prometheus" {
  name       = "wsc2026-prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = "wsc2026-logging"

  values = [file("${path.module}/values.yaml")]
}
