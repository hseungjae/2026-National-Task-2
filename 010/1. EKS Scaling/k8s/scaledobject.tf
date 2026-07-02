resource "kubernetes_manifest" "keda_scaler" {
  manifest = {
    apiVersion = "keda.sh/v1alpha1"
    kind       = "ScaledObject"
    metadata = {
      name      = "wsi-keda-scaler"
      namespace = kubernetes_namespace.wsi_app.metadata[0].name
    }
    spec = {
      scaleTargetRef = {
        name = "wsi-worker-app"
      }
      minReplicaCount = 0
      maxReplicaCount = 20
      pollingInterval = 10
      cooldownPeriod  = 3
      triggers = [
        {
          type = "aws-sqs-queue"
          metadata = {
            queueURL      = var.queue_url
            queueLength   = "1"
            awsRegion     = var.region
            identityOwner = "operator"
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_deployment.worker]
}
