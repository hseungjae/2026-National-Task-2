resource "kubernetes_namespace" "wsi_app" {
  metadata {
    name = "wsi-app"
  }
}
