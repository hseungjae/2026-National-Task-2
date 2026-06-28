resource "aws_ec2_tag" "cluster_sg_karpenter" {
  resource_id = module.eks.cluster_security_group_id
  key         = "karpenter.sh/discovery"
  value       = "${var.prefix}-eks"
}
