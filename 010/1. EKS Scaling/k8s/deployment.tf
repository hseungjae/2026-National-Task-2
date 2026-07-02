resource "kubernetes_deployment" "worker" {
  metadata {
    name      = "wsi-worker-app"
    namespace = kubernetes_namespace.wsi_app.metadata[0].name
  }

  spec {
    replicas = 0

    selector {
      match_labels = {
        app = "wsi-worker-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "wsi-worker-app"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.worker_sa.metadata[0].name

        node_selector = {
          "karpenter.sh/nodepool" = "wsi-nodepool"
        }

        container {
          name    = "worker"
          image   = "python:3.11-slim"
          command = ["sh", "-c"]
          args    = ["pip install --no-cache-dir -q boto3 || pip install --no-cache-dir -q boto3\nexec python /app/app.py\n"]

          env {
            name  = "QUEUE_URL"
            value = var.queue_url
          }

          resources {
            requests = {
              cpu    = "200m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
          }

          volume_mount {
            name       = "code"
            mount_path = "/app"
          }
        }

        volume {
          name = "code"
          config_map {
            name = kubernetes_config_map.worker_code.metadata[0].name
          }
        }
      }
    }
  }
  depends_on = [ kubernetes_namespace.wsi_app, kubernetes_service_account.worker_sa ]
}
