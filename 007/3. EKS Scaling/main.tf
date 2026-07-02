module "vpc" {
  source = "./vpc"
  prefix = var.prefix
}

module "ecr" {
  source = "./ecr"
  prefix = var.prefix
}

module "sqs" {
  source = "./sqs"
  prefix = var.prefix
}

module "eks" {
  source      = "./eks"
  prefix      = var.prefix
  vpc_id      = module.vpc.vpc_id
  subnets     = module.vpc.subnet_ids
  k8s_version = var.k8s_version
}

module "karpenter" {
  source            = "./karpenter_module"
  cluster_name      = module.eks.cluster_name
  region            = var.region
  karpenter_version = var.karpenter_version
  account_id        = local.account_id

  depends_on = [module.eks]
}

module "keda" {
  source                  = "./keda_module"
  prefix                  = var.prefix
  oidc_provider_arn       = module.eks.oidc_provider_arn
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url

  depends_on = [module.eks]
}

module "k8s" {
  source                  = "./k8s"
  prefix                  = var.prefix
  oidc_provider_arn       = module.eks.oidc_provider_arn
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  region                  = var.region
  ecr_image_uri           = module.ecr.repository_url
  sqs_queue_url           = module.sqs.queue_url
  cluster_name            = module.eks.cluster_name
  alias_version           = local.alias_version

  depends_on = [module.eks, module.keda, module.karpenter]
}
