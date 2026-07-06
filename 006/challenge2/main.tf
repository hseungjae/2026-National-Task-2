resource "aws_s3_bucket" "scripts" {
  bucket        = "gj2026-data-scripts-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = { Name = "gj2026-data-scripts" }
}

resource "aws_s3_bucket_public_access_block" "scripts" {
  bucket                  = aws_s3_bucket.scripts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "app_py" {
  bucket = aws_s3_bucket.scripts.id
  key    = "app.py"
  source = "${path.root}/../배포파일/Real-time data analytics/app.py"
  etag   = filemd5("${path.root}/../배포파일/Real-time data analytics/app.py")
}

resource "aws_s3_object" "setup_kafka" {
  bucket = aws_s3_bucket.scripts.id
  key    = "setup_kafka.sh"
  source = "${path.root}/script/setup_kafka.sh"
  etag   = filemd5("${path.root}/script/setup_kafka.sh")
}

module "ec2" {
  source         = "./ec2"
  vpc_id         = aws_default_vpc.default.id
  subnet_id      = data.aws_subnets.default.ids[0]
  ami_id         = data.aws_ami.amazon_linux_2023.id
  instance_type  = var.instance_type
  key_name       = var.key_name
  scripts_bucket = aws_s3_bucket.scripts.id

  depends_on = [aws_s3_object.app_py, aws_s3_object.setup_kafka]
}

module "nlb" {
  source            = "./nlb"
  subnet_id         = data.aws_subnets.default.ids[0]
  vpc_id            = aws_default_vpc.default.id
  kafka_instance_id = module.ec2.kafka_instance_id
  kafka_private_ip  = module.ec2.kafka_private_ip
}

module "flink" {
  source = "./flink"
}
