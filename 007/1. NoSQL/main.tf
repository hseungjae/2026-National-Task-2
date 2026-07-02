module "dynamodb" {
  source = "./dynamodb"
  prefix = var.prefix
}

module "lambda" {
  source                = "./lambda"
  prefix                = var.prefix
  reserve_ddb_arn       = module.dynamodb.reserve_ddb_stream_arn
  reserve_ddb_table_arn = module.dynamodb.reservation_table_arn
  audit_ddb_arn         = module.dynamodb.audit_ddb_arn
}

module "ec2" {
  source      = "./ec2"
  prefix      = var.prefix
  al2023_ami  = data.aws_ami.al2023_ami.id
  region      = var.region
  table_name  = module.dynamodb.reservation_table_name
  gsi_name    = module.dynamodb.reservation_gsi_name
}