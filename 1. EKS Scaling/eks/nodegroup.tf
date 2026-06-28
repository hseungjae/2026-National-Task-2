resource "aws_eks_node_group" "node" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "${var.prefix}-system"
  node_role_arn   = aws_iam_role.nodegroup_role.arn
  subnet_ids      = var.private_subnets

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  instance_types = ["t3.medium"]
  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"

  taint {
    key    = "dedicated"
    value  = "system"
    effect = "NO_SCHEDULE"
  }
  
  tags = {
    "Name" = "${var.prefix}-system"
  }

  depends_on = [ module.eks ]
}