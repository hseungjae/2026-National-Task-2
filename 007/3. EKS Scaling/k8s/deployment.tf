resource "kubernetes_deployment" "order_processor" {
  metadata {
    name      = "order-processor"
    namespace = kubernetes_namespace.skillsmkt.metadata[0].name
    labels = {
      app = "order-processor"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "order-processor"
      }
    }

    template {
      metadata {
        labels = {
          app = "order-processor"
        }
      }

      spec {
        service_account_name             = kubernetes_service_account.order_sa.metadata[0].name
        termination_grace_period_seconds = 10

        node_selector = {
          "karpenter.sh/nodepool" = "${var.prefix}-app-nodepool"
        }

        toleration {
          key      = "dedicated"
          operator = "Equal"
          value    = "app"
          effect   = "NoSchedule"
        }

        container {
          name  = "order-processor"
          image = "${var.ecr_image_uri}:latest"

          port {
            container_port = 8080
          }

          resources {
            requests = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          env {
            name  = "AWS_REGION"
            value = var.region
          }

          env {
            name  = "SQS_QUEUE_URL"
            value = var.sqs_queue_url
          }

          env {
            name  = "PROCESSING_TIME"
            value = "3"
          }
        }
      }
    }
  }
  depends_on = [ kubernetes_manifest.app_nodeclass ]
}
