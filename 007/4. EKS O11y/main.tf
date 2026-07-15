module "vpc" {
  source = "./vpc"
  prefix = var.prefix
}

module "ecr" {
  source = "./ecr"
  prefix = var.prefix
}

module "eks" {
  source      = "./eks"
  prefix      = var.prefix
  vpc_id      = module.vpc.vpc_id
  subnets     = module.vpc.subnet_ids
  k8s_version = var.k8s_version
}

module "lb_controller" {
  source            = "./lb_controller"
  prefix            = var.prefix
  region            = var.region
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer_url   = module.eks.cluster_oidc_issuer_url
  vpc_id            = module.vpc.vpc_id

  depends_on = [module.eks]
}

module "app" {
  source        = "./app"
  prefix        = var.prefix
  ecr_image_uri = module.ecr.repository_url
  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.subnet_ids

  depends_on = [module.eks, module.lb_controller]
}

module "loki" {
  source = "./loki_module"

  depends_on = [module.eks]
}

module "otel" {
  source = "./otel"

  monitoring_namespace = module.loki.namespace
  loki_url             = module.loki.loki_url

  depends_on = [module.eks, module.loki]
}

module "grafana" {
  source               = "./grafana_module"
  prefix               = var.prefix
  admin_user           = var.grafana_admin_user
  admin_password       = var.grafana_admin_password
  monitoring_namespace = module.loki.namespace
  loki_url             = module.loki.loki_url
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.subnet_ids

  depends_on = [module.eks, module.lb_controller, module.loki]
}
