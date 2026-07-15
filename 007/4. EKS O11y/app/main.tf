resource "kubernetes_namespace" "o11y" {
  metadata {
    name = "o11y"
  }
}

resource "kubernetes_deployment" "log_generator" {
  metadata {
    name      = "log-generator"
    namespace = kubernetes_namespace.o11y.metadata[0].name
    labels = {
      app = "log-generator"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "log-generator"
      }
    }

    template {
      metadata {
        labels = {
          app = "log-generator"
        }
      }

      spec {
        container {
          name  = "log-generator"
          image = "${var.ecr_image_uri}:latest"

          port {
            container_port = 8080
          }

          readiness_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "log_generator" {
  metadata {
    name      = "log-generator"
    namespace = kubernetes_namespace.o11y.metadata[0].name
  }

  spec {
    selector = {
      app = "log-generator"
    }
    port {
      port        = 80
      target_port = 8080
    }
    type = "ClusterIP"
  }
}
