data "aws_eks_addon_version" "coredns" {
  addon_name         = "coredns"
  kubernetes_version = module.eks.cluster_version

  most_recent = true
}

data "aws_eks_addon_version" "pod_identity_agent" {
  addon_name         = "eks-pod-identity-agent"
  kubernetes_version = module.eks.cluster_version

  most_recent = true
}

resource "aws_eks_addon" "coredns" {
  cluster_name  = module.eks.cluster_name
  addon_name    = "coredns"
  addon_version = data.aws_eks_addon_version.coredns.version

  configuration_values = jsonencode({
    tolerations = [
      {
        key      = "dedicated"
        operator = "Equal"
        value    = "system"
        effect   = "NoSchedule"
      }
    ]
  })

  depends_on = [ aws_eks_node_group.node ]
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name  = module.eks.cluster_name
  addon_name    = "eks-pod-identity-agent"
  addon_version = data.aws_eks_addon_version.pod_identity_agent.version

  depends_on = [ aws_eks_node_group.node ]
}