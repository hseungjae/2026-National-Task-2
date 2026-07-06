resource "kubernetes_service" "log_generator" {
  metadata {
    name      = "log-generator"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    type = "LoadBalancer"

    selector = {
      app = "log-generator"
    }

    port {
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }
  }

  depends_on = [ kubernetes_deployment_v1.book ]
}
