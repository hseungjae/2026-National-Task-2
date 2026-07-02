resource "kubernetes_manifest" "app_nodepool" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "${var.prefix}-app-nodepool"
    }
    spec = {
      template = {
        spec = {
          requirements = [
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = ["t3.small", "t3.medium"]
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            }
          ]
          taints = [
            {
              key    = "dedicated"
              value  = "app"
              effect = "NoSchedule"
            }
          ]
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = "${var.prefix}-app-nodeclass"
          }
          expireAfter = "720h"
        }
      }
      limits = {
        cpu = "1000"
      }
      disruption = {
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = "60s"
      }
    }
  }

  depends_on = [kubernetes_namespace.skillsmkt]
}

resource "kubernetes_manifest" "app_nodeclass" {
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "${var.prefix}-app-nodeclass"
    }
    spec = {
      role = "KarpenterNodeRole-${var.cluster_name}"
      amiSelectorTerms = [
        { alias = "al2023@${var.alias_version}" }
      ]
      subnetSelectorTerms = [
        { tags = { "karpenter.sh/discovery" = var.cluster_name } }
      ]
      securityGroupSelectorTerms = [
        { tags = { "karpenter.sh/discovery" = var.cluster_name } }
      ]
    }
  }
}
