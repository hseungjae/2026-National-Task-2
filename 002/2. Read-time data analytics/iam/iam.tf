data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "ec2_role" {
  name = "wsc2026-analytics-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "wsc2026-analytics-ec2-role" }
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "ec2_kinesis" {
  name = "wsc2026-analytics-ec2-kinesis-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:PutRecord",
          "kinesis:PutRecords",
          "kinesis:DescribeStream",
          "kinesis:ListStreams",
        ]
        Resource = "arn:aws:kinesis:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stream/wsc2026-order-stream"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "wsc2026-analytics-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role" "flink_role" {
  name = "wsc2026-analytics-flink-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "kinesisanalytics.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "wsc2026-analytics-flink-role" }
}

resource "aws_iam_role_policy_attachment" "flink_admin" {
  role       = aws_iam_role.flink_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
