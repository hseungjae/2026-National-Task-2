resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  namespace  = "logging"

  values = [file("${path.module}/values.yaml")]

  force_update = true
}
