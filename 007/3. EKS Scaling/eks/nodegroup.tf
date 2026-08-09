resource "aws_eks_node_group" "node" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "${var.prefix}-cluster-addon-ng"
  node_role_arn   = aws_iam_role.nodegroup_role.arn
  subnet_ids      = var.subnets

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  instance_types = ["t3.medium"]
  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"

  launch_template {
    id      = aws_launch_template.node.id
    version = "$Latest"
  }

  taint {
    key    = "dedicated"
    value  = "addon"
    effect = "NO_SCHEDULE"
  }
  
  tags = {
    "Name" = "${var.prefix}-cluster-addon-ng"
  }

  depends_on = [ module.eks ]
}