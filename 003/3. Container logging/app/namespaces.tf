resource "kubernetes_namespace" "app" {
  metadata {
    name = "wsc2026-app"
  }
}

resource "kubernetes_namespace" "logging" {
  metadata {
    name = "wsc2026-logging"
  }
}
