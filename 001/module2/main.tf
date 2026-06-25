# ── Module 2: RDS Connection (ap-northeast-1) ────────────────────────────────
# network → secrets → rds → proxy → lambda 순으로 의존성 구성

module "network" {
  source = "./network"
}

module "secrets" {
  source      = "./secrets"
  db_username = var.db_username
  db_password = var.db_password
  db_name     = "wsc2026"
}

module "rds" {
  source            = "./rds"
  subnet_group_name = module.network.db_subnet_group_name
  sg_id             = module.network.rds_sg_id
  db_username       = var.db_username
  db_password       = var.db_password
}

module "proxy" {
  source                 = "./proxy"
  secret_arn             = module.secrets.secret_arn
  secret_id              = module.secrets.secret_id
  subnet_ids             = module.network.db_subnet_ids
  sg_id                  = module.network.rds_sg_id
  db_instance_identifier = module.rds.db_identifier
  db_username            = var.db_username
  db_password            = var.db_password
  db_name                = "wsc2026"

  depends_on = [module.rds]
}

module "lambda" {
  source        = "./lambda"
  function_name = var.function_name
  secret_name   = module.secrets.secret_name
  secret_arn    = module.secrets.secret_arn
  subnet_ids    = module.network.db_subnet_ids
  sg_id         = module.network.rds_sg_id
  # proxy 생성 + secret 의 host 업데이트 완료 후 lambda 생성
  depends_on = [module.proxy]
}
