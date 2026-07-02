resource "kubernetes_manifest" "nodepool" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "wsi-nodepool"
    }
    spec = {
      template = {
        spec = {
          requirements = [
            {
              key      = "karpenter.k8s.aws/instance-family"
              operator = "In"
              values   = ["c5"]
            }
          ]
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = "wsi-nodeclass"
          }
          expireAfter = "720h"
        }
      }
      limits = {
        cpu = 1000
      }
      disruption = {
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = "1m"
      }
    }
  }

  depends_on = [kubernetes_manifest.nodeclass]
}

resource "kubernetes_manifest" "nodeclass" {
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "wsi-nodeclass"
    }
    spec = {
      role = "KarpenterNodeRole-${var.cluster_name}"
      amiSelectorTerms = [
        { alias = "al2023@latest" }
      ]
      subnetSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = var.cluster_name
          }
        }
      ]
      securityGroupSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = var.cluster_name
          }
        }
      ]
    }
  }
}
