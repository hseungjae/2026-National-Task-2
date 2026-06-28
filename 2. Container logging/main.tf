module "vpc" {
  source = "./vpc"
  region = var.region
  prefix = var.prefix
}

module "eks" {
  source = "./eks"
  region = var.region
  prefix = var.prefix
  vpc_id = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
}

module "k8s" {
  source = "./k8s"

  depends_on = [module.eks]
}

module "lb_controller" {
  source                = "./lb_controller"
  prefix                = var.prefix
  cluster_name          = module.eks.cluster_name
  vpc_id                = module.vpc.vpc_id
  region                = var.region
  eks_oidc_provider_arn = module.eks.oidc_provider_arn

  depends_on = [module.eks]
}

module "loki" {
  source = "./loki_module"

  depends_on = [module.k8s, module.lb_controller]
}

module "fluent_bit" {
  source = "./fluentbit_module"

  depends_on = [module.k8s, module.lb_controller]
}

module "grafana" {
  source = "./grafana_module"

  depends_on = [module.k8s, module.lb_controller]
}


