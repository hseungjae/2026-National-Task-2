resource "kubernetes_service" "nginx" {
  metadata {
    name      = "nginx-service"
    namespace = kubernetes_namespace.logging.metadata[0].name
  }

  spec {
    selector = {
      app = "nginx"
    }

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }
  }

  depends_on = [kubernetes_namespace.logging]
}
