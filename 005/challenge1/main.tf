locals {
  oidc_provider     = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
  oidc_provider_arn = aws_iam_openid_connect_provider.eks.arn
}

resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "EKS cluster security group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name                     = "${var.cluster_name}-cluster-sg"
    "karpenter.sh/discovery" = var.cluster_name
  }
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = "1.35"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = concat(module.vpc.private_subnet_ids, module.vpc.public_subnet_ids)
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  access_config {
    authentication_mode = "API"
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster, module.vpc]
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_eks_access_entry" "node" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = module.iam.node_role_arn
  type          = "EC2_LINUX"
  depends_on    = [aws_eks_cluster.this]
}

resource "aws_eks_access_entry" "bastion" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = module.iam.bastion_role_arn
  depends_on    = [aws_eks_cluster.this, module.iam]
}

resource "aws_eks_access_policy_association" "bastion_admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = module.iam.bastion_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope { type = "cluster" }
  depends_on    = [aws_eks_access_entry.bastion]
}

resource "aws_eks_access_entry" "caller" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = data.aws_caller_identity.current.arn
  depends_on    = [aws_eks_cluster.this]
}

resource "aws_eks_access_policy_association" "caller_admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = data.aws_caller_identity.current.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope { type = "cluster" }
  depends_on    = [aws_eks_access_entry.caller]
}

module "vpc" {
  source       = "./vpc"
  cluster_name = var.cluster_name
}

module "sqs" {
  source = "./sqs"
}

module "iam" {
  source            = "./iam"
  cluster_name      = var.cluster_name
  oidc_provider     = local.oidc_provider
  oidc_provider_arn = local.oidc_provider_arn
  depends_on        = [aws_eks_cluster.this]
}

module "ec2" {
  source                = "./ec2"
  public_subnet_id      = module.vpc.public_subnet_a_id
  ami_id                = data.aws_ami.amazon_linux_2023.id
  instance_profile_name = module.iam.bastion_instance_profile_name
  vpc_id                = module.vpc.vpc_id
}

module "eks" {
  source             = "./eks"
  cluster_name       = var.cluster_name
  node_role_arn      = module.iam.node_role_arn
  private_subnet_ids = module.vpc.private_subnet_ids
  depends_on         = [aws_eks_cluster.this, module.iam]
}

module "kubernetes" {
  source           = "./kubernetes"
  cluster_name     = var.cluster_name
  region           = var.region
  account_id       = data.aws_caller_identity.current.account_id
  sqs_queue_url    = module.sqs.queue_url
  node_role_name   = module.iam.node_role_name
  depends_on       = [module.eks, aws_eks_access_policy_association.caller_admin]
}
