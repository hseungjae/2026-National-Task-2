resource "helm_release" "keda" {
  name             = "keda"
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  namespace        = "keda"
  create_namespace = true

  values = [yamlencode({
    serviceAccount = {
      operator = {
        name = "keda-operator"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.keda_operator_role.arn
        }
      }
    }
    tolerations = [
      {
        key      = "dedicated"
        operator = "Equal"
        value    = "addon"
        effect   = "NoSchedule"
      }
    ]
  })]
}
