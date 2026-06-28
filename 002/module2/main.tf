module "vpc" {
  source             = "./vpc"
  availability_zones = data.aws_availability_zones.available.names
}

module "iam" {
  source = "./iam"
}

module "kinesis" {
  source = "./kinesis"
}

module "ec2" {
  source                = "./ec2"
  vpc_id                = module.vpc.vpc_id
  private_subnet_a_id   = module.vpc.private_subnet_a_id
  public_subnet_a_id    = module.vpc.public_subnet_a_id
  ec2_role_name         = module.iam.ec2_instance_profile_name
  instance_type         = var.instance_type
  ami_id                = data.aws_ami.amazon_linux_2023.id
  kinesis_stream_name   = module.kinesis.stream_name

  depends_on = [module.iam, module.kinesis]
}

module "alb" {
  source              = "./alb"
  vpc_id              = module.vpc.vpc_id
  public_subnet_a_id  = module.vpc.public_subnet_a_id
  public_subnet_b_id  = module.vpc.public_subnet_b_id
  ec2_instance_id     = module.ec2.instance_id
  ec2_sg_id           = module.ec2.ec2_sg_id

  depends_on = [module.ec2]
}

module "flink" {
  source             = "./flink"
  flink_role_arn     = module.iam.flink_role_arn
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = [module.vpc.private_subnet_a_id, module.vpc.private_subnet_b_id]
  kinesis_stream_arn = module.kinesis.stream_arn

  depends_on = [module.kinesis, module.iam]
}
