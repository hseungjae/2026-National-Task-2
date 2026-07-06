resource "helm_release" "fluent_bit" {
  name       = "wsc2026-fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  namespace  = "wsc2026-logging"

  values = [file("${path.module}/values.yaml")]
}
