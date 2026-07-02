resource "helm_release" "karpenter" {
  name      = "karpenter"
  chart     = "oci://public.ecr.aws/karpenter/karpenter"
  version   = var.karpenter_version
  namespace = "kube-system"

  values = [
    yamlencode({
      settings = {
        clusterName       = var.cluster_name
        interruptionQueue = var.cluster_name
      }
      controller = {
        env = [
          {
            name  = "AWS_REGION"
            value = var.region
          }
        ]
        resources = {
          requests = {
            cpu    = "250m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }
      tolerations = [
        {
          key      = "dedicated"
          operator = "Equal"
          value    = "system"
          effect   = "NoSchedule"
        }
      ]
    })
  ]

  depends_on = [aws_eks_pod_identity_association.karpenter]
}
