resource "aws_eks_node_group" "node" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "${var.prefix}-cluster-ng"
  node_role_arn   = aws_iam_role.nodegroup_role.arn
  subnet_ids      = var.subnets

  # 고가용성: Multi-AZ 배치 (2/2/2)
  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  instance_types = ["t3.medium"]
  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"

  tags = {
    "Name" = "${var.prefix}-cluster-ng-node"
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    module.eks,
  ]
}
