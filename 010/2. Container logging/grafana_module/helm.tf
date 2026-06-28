resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = "logging"

  values = [file("${path.module}/values.yaml")]

  force_update = true
}
