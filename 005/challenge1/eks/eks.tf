resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = "wsc-scaling-node"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = ["t3.medium"]

  labels = {
    dedicated = "scaling"
  }

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 10
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    Name                     = "wsc-scaling-node"
    "karpenter.sh/discovery" = var.cluster_name
  }
}

resource "aws_eks_addon" "coredns" {
  cluster_name = var.cluster_name
  addon_name   = "coredns"
  depends_on   = [aws_eks_node_group.this]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = var.cluster_name
  addon_name   = "vpc-cni"
  depends_on   = [aws_eks_node_group.this]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = var.cluster_name
  addon_name   = "kube-proxy"
  depends_on   = [aws_eks_node_group.this]
}
