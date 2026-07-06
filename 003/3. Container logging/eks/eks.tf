module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.prefix}-logging-cluster"
  cluster_version = "1.35"

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false

  create_iam_role = true

  enable_cluster_creator_admin_permissions = true

  vpc_id     = var.vpc_id
  subnet_ids = concat(var.public_subnet_ids, var.private_subnet_ids)

  eks_managed_node_groups = {
    "${var.prefix}-logging-nodegroup" = {
      name = "${var.prefix}-logging-nodegroup"

      iam_role_name            = "${var.prefix}-node-role"
      iam_role_use_name_prefix = false

      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]
      disk_size      = 20

      subnet_ids = var.private_subnet_ids

      min_size     = 2
      max_size     = 2
      desired_size = 2
    }
  }
}
