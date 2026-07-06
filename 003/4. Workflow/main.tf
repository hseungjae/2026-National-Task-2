module "s3" {
  source = "./s3"
  prefix = var.prefix
}

module "dynamodb" {
  source = "./dynamodb"
  prefix = var.prefix
}

module "lambda" {
  source = "./lambda"
  prefix = var.prefix
}

module "step_functions" {
  source           = "./step_functions"
  prefix           = var.prefix
  bucket_arn       = module.s3.bucket_arn
  orders_table_arn = module.dynamodb.orders_table_arn
  inventory_arn    = module.dynamodb.inventory_table_arn
  history_arn      = module.dynamodb.history_table_arn
  validator_arn    = module.lambda.validator_arn
  payment_arn      = module.lambda.payment_arn
}
