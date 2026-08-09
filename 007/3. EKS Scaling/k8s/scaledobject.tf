resource "kubernetes_manifest" "order_scaler" {
  manifest = {
    apiVersion = "keda.sh/v1alpha1"
    kind       = "ScaledObject"
    metadata = {
      name      = "order-scaler"
      namespace = kubernetes_namespace.skillsmkt.metadata[0].name
    }
    spec = {
      scaleTargetRef = {
        name = "order-processor"
      }
      minReplicaCount = 1
      maxReplicaCount = 5
      advanced = {
        horizontalPodAutoscalerConfig = {
          behavior = {
            scaleDown = {
              stabilizationWindowSeconds = 3
            }
          }
        }
      }
      triggers = [
        {
          type = "aws-sqs-queue"
          metadata = {
            queueURL      = var.sqs_queue_url
            queueLength   = "5"
            awsRegion     = var.region
            identityOwner = "operator"
          }
        }
      ]
    }
  }

}

