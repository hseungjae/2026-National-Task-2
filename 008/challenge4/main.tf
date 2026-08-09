locals {
  oidc_provider     = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
  oidc_provider_arn = aws_iam_openid_connect_provider.eks.arn
}

# EKS 클러스터는 root에 유지 (kubernetes/helm provider가 이 리소스에 의존)
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
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster, module.vpc]
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_eks_addon" "coredns" {
  cluster_name         = aws_eks_cluster.this.name
  addon_name           = "coredns"
  configuration_values = jsonencode({
    computeType = "Fargate"
    corefile = <<-EOT
      .:53 {
          errors
          health {
              lameduck 5s
            }
          ready
          kubernetes cluster.local in-addr.arpa ip6.arpa {
            pods insecure
            fallthrough in-addr.arpa ip6.arpa
          }
          prometheus :9153
          forward . 169.254.169.253
          cache 30
          loop
          reload
          loadbalance
      }
    EOT
  })
  depends_on           = [module.fargate]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "vpc-cni"
  depends_on   = [module.fargate]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "kube-proxy"
  depends_on   = [module.fargate]
}

resource "aws_eks_access_entry" "node" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = module.iam.node_role_arn
  type          = "EC2_LINUX"
  depends_on    = [aws_eks_cluster.this]
}


module "vpc" {
  source       = "./vpc"
  cluster_name = var.cluster_name
  region       = var.region
}

module "iam" {
  source            = "./iam"
  cluster_name      = var.cluster_name
  oidc_provider     = local.oidc_provider
  oidc_provider_arn = local.oidc_provider_arn
  depends_on        = [aws_eks_cluster.this]
}

module "fargate" {
  source             = "./fargate"
  cluster_name       = var.cluster_name
  fargate_role_arn   = module.iam.fargate_role_arn
  private_subnet_ids = module.vpc.private_subnet_ids
  depends_on         = [aws_eks_cluster.this, module.iam]
}

module "sqs" {
  source = "./sqs"
}

module "ecr" {
  source = "./ecr"
}
