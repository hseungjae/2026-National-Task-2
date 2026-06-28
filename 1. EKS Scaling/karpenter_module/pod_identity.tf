data "aws_iam_policy_document" "karpenter_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "karpenter" {
  name               = "${var.cluster_name}-karpenter"
  assume_role_policy = data.aws_iam_policy_document.karpenter_assume.json

  depends_on = [aws_cloudformation_stack.karpenter]
}

locals {
  karpenter_policies = [
    "KarpenterControllerNodeLifecyclePolicy-${var.cluster_name}",
    "KarpenterControllerIAMIntegrationPolicy-${var.cluster_name}",
    "KarpenterControllerEKSIntegrationPolicy-${var.cluster_name}",
    "KarpenterControllerInterruptionPolicy-${var.cluster_name}",
    "KarpenterControllerResourceDiscoveryPolicy-${var.cluster_name}",
    "KarpenterControllerZonalShiftPolicy-${var.cluster_name}",
  ]
}

resource "aws_iam_role_policy_attachment" "karpenter" {
  for_each = toset(local.karpenter_policies)

  role       = aws_iam_role.karpenter.name
  policy_arn = "arn:aws:iam::${var.account_id}:policy/${each.value}"
}

resource "aws_eks_pod_identity_association" "karpenter" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "karpenter"
  role_arn        = aws_iam_role.karpenter.arn
}

resource "aws_eks_access_entry" "karpenter_nodes" {
  cluster_name  = var.cluster_name
  principal_arn = "arn:aws:iam::${var.account_id}:role/KarpenterNodeRole-${var.cluster_name}"
  type          = "EC2_LINUX"

  depends_on = [aws_cloudformation_stack.karpenter]
}
