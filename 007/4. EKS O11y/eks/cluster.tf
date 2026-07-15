module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${var.prefix}-cluster"
  kubernetes_version = var.k8s_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnets

  endpoint_public_access  = true
  endpoint_private_access = true

  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true

  enable_irsa = true

  addons = {
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
  }
}
