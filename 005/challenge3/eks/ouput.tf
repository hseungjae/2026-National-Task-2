output "node_group_name" {
  value = aws_eks_node_group.this.node_group_name
}

output "gp2_default_annotation" {
  value = kubernetes_annotations.gp2_default.id
}
