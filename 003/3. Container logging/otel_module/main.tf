resource "helm_release" "otel" {
  name       = "wsc2026-otel-collector"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  namespace  = "wsc2026-logging"

  values = [file("${path.module}/values.yaml")]
}
