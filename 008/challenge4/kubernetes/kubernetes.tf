resource "kubernetes_namespace" "skills_sqs" {
  metadata {
    name = "skills-sqs"
  }
}

resource "kubernetes_service_account" "worker" {
  metadata {
    name      = "sqs-worker-sa"
    namespace = kubernetes_namespace.skills_sqs.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = var.worker_role_arn
    }
  }
}

resource "kubernetes_deployment" "worker" {
  metadata {
    name      = "sqs-worker"
    namespace = kubernetes_namespace.skills_sqs.metadata[0].name
  }

  spec {
    replicas = 0

    selector {
      match_labels = { app = "sqs-worker" }
    }

    template {
      metadata {
        labels = { app = "sqs-worker" }
      }

      spec {
        service_account_name = kubernetes_service_account.worker.metadata[0].name

        container {
          name  = "worker"
          image = "${var.ecr_repository_url}:latest"

          env {
            name  = "SQS_QUEUE_URL"
            value = var.sqs_queue_url
          }
          env {
            name  = "AWS_REGION"
            value = var.region
          }
          env {
            name  = "PROCESSING_SECONDS"
            value = "5"
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service_account.worker]
}

