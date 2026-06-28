resource "kubernetes_ingress_v1" "logging" {
  metadata {
    name      = "logging-ingress"
    namespace = kubernetes_namespace.logging.metadata[0].name
    annotations = {
      "alb.ingress.kubernetes.io/scheme"            = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"       = "ip"
      "alb.ingress.kubernetes.io/load-balancer-name" = "wsc2026-logging-alb"
      "alb.ingress.kubernetes.io/listen-ports"      = "[{\"HTTP\": 80}]"
      "alb.ingress.kubernetes.io/success-codes"     = "200-399"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      http {
        path {
          path      = "/logging"
          path_type = "Prefix"
          backend {
            service {
              name = "grafana"
              port {
                number = 3000
              }
            }
          }
        }

        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "nginx-service"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.logging]
}
