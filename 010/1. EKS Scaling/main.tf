module "vpc" {
  source = "./vpc"
  region = var.region
  prefix = var.prefix
}

module "bastion" {
  source = "./bastion"
  public_subnets = module.vpc.public_subnets
  vpc_id = module.vpc.vpc_id
  prefix = var.prefix
  al2023_ami = data.aws_ami.al2023_ami.id
}

module "eks" {
  source = "./eks"
  region = var.region
  prefix = var.prefix
  vpc_id = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  bastion_role_arn = module.bastion.bastion_role_arn
  bastion_sg_id = module.bastion.bastion_sg_id
}

module "sqs" {
  source = "./sqs"
  prefix = var.prefix
}

module "karpenter" {
  source = "./karpenter_module"

  prefix       = var.prefix
  region       = var.region
  cluster_name = module.eks.cluster_name
  account_id   = data.aws_caller_identity.current.account_id

  depends_on = [module.eks]
}

module "keda" {
  source = "./keda_module"

  prefix            = var.prefix
  region            = var.region
  oidc_provider_arn = module.eks.oidc_provider_arn
  queue_arn         = module.sqs.queue_arn

  depends_on = [module.eks]
}

module "k8s" {
  source = "./k8s"

  prefix            = var.prefix
  region            = var.region
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  queue_url         = module.sqs.queue_url

  depends_on = [module.eks, module.keda, module.karpenter]
}