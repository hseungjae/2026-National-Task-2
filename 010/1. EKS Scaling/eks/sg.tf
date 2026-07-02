resource "aws_vpc_security_group_ingress_rule" "bastion_to_eks" {
  security_group_id            = module.eks.cluster_security_group_id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.bastion_sg_id
}
