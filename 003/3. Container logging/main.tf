module "vpc" {
  source = "./vpc"
  prefix = var.prefix
  region = var.region
}

module "eks" {
  source = "./eks"
  prefix = var.prefix

  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
}

module "app" {
  source = "./app"

  cluster_name = module.eks.cluster_name
}

module "otel" {
  source = "./otel_module"

  depends_on = [module.app]
}

module "loki" {
  source = "./loki_module"

  depends_on = [module.app]
}

module "prometheus" {
  source = "./prometheus_module"

  depends_on = [module.app]
}

module "grafana" {
  source = "./grafana_module"

  grafana_admin_password = var.grafana_admin_password

  depends_on = [module.prometheus, module.loki]
}

module "fluentbit" {
  source = "./fluentbit_module"

  depends_on = [module.app]
}
