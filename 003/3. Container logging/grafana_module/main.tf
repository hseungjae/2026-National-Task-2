resource "helm_release" "grafana" {
  name       = "wsc2026-grafana"
  repository = "https://grafana-community.github.io/helm-charts"
  chart      = "grafana"
  namespace  = "wsc2026-logging"

  values = [
    templatefile("${path.module}/values.yaml", {
      admin_password = var.grafana_admin_password
    })
  ]
}
