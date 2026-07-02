module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${var.prefix}-eks"
  kubernetes_version = "1.35"

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  endpoint_public_access  = true
  endpoint_private_access = true

  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true

  enable_irsa = true

  node_security_group_tags = {
    "karpenter.sh/discovery" = "${var.prefix}-eks"
  }



  addons = {
    "vpc-cni" = {
      "enable"    = true
      most_recent = true
    }

    kube-proxy = {
      "enable"    = true
      most_recent = true
    }
  }
}
