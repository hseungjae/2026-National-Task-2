resource "helm_release" "karpenter" {
  name             = "karpenter"
  chart            = "oci://public.ecr.aws/karpenter/karpenter"
  version          = var.karpenter_version
  namespace        = "kube-system"
  create_namespace = true

  values = [
    yamlencode({
      replicas = 1
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
            cpu    = "0.25"
            memory = "256Mi"
          }
          limits = {
            cpu    = "0.5"
            memory = "512Mi"
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
    })
  ]
}
