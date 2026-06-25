variable "cluster_name" {}
variable "node_role_arn" {}
variable "private_subnet_ids" { type = list(string) }
variable "ebs_csi_role_arn" {}
