resource "aws_eks_fargate_profile" "karpenter" {
  cluster_name           = var.cluster_name
  fargate_profile_name   = "skills-sqs-fp-karpenter"
  pod_execution_role_arn = var.fargate_role_arn
  subnet_ids             = var.private_subnet_ids

  selector { namespace = "karpenter" }
}

resource "aws_eks_fargate_profile" "keda" {
  cluster_name           = var.cluster_name
  fargate_profile_name   = "skills-sqs-fp-keda"
  pod_execution_role_arn = var.fargate_role_arn
  subnet_ids             = var.private_subnet_ids

  selector { namespace = "keda" }
}

resource "aws_eks_fargate_profile" "kube_system" {
  cluster_name           = var.cluster_name
  fargate_profile_name   = "skills-sqs-fp-addon"
  pod_execution_role_arn = var.fargate_role_arn
  subnet_ids             = var.private_subnet_ids

  selector { namespace = "kube-system" }
}
