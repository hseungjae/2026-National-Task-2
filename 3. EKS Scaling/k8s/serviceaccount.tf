resource "kubernetes_service_account" "order_sa" {
  metadata {
    name      = "order-sa"
    namespace = kubernetes_namespace.skillsmkt.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.order_sa_role.arn
    }
  }
}
