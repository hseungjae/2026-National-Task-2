output "namespace" {
  value = kubernetes_namespace.scaling.metadata[0].name
}
