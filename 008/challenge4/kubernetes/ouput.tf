output "namespace" {
  value = kubernetes_namespace.skills_sqs.metadata[0].name
}

output "worker_deployment_name" {
  value = kubernetes_deployment.worker.metadata[0].name
}
