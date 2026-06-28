resource "aws_iam_role" "msk_ec2" {
  name = "wsc2026-msk-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "wsc2026-msk-ec2-role" }
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.msk_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_admin" {
  role       = aws_iam_role.msk_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy" "msk_ec2_policy" {
  name = "wsc2026-msk-ec2-policy"
  role = aws_iam_role.msk_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:AlterCluster",
          "kafka-cluster:DescribeCluster",
          "kafka-cluster:DescribeClusterDynamicConfiguration",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:CreateTopic",
          "kafka-cluster:WriteData",
          "kafka-cluster:WriteDataIdempotently",
          "kafka-cluster:ReadData",
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DescribeGroup",
        ]
        Resource = [
          "arn:aws:kafka:${var.region}:${var.account_id}:cluster/wsc2026-msk-cluster/*",
          "arn:aws:kafka:${var.region}:${var.account_id}:topic/wsc2026-msk-cluster/*",
          "arn:aws:kafka:${var.region}:${var.account_id}:group/wsc2026-msk-cluster/*",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kafka:GetBootstrapBrokers",
          "kafka:DescribeCluster",
          "kafka:ListClusters",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Resource = [
          "arn:aws:s3:::wsc2026-sensor-alert-bucket-*",
          "arn:aws:s3:::wsc2026-sensor-alert-bucket-*/*",
        ]
      },
    ]
  })
}

resource "aws_iam_instance_profile" "msk_ec2" {
  name = "wsc2026-msk-ec2-profile"
  role = aws_iam_role.msk_ec2.name
}

resource "aws_iam_role" "msk_lambda" {
  name = "wsc2026-msk-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "wsc2026-msk-lambda-role" }
}

resource "aws_iam_role_policy" "msk_lambda_policy" {
  name = "wsc2026-msk-lambda-policy"
  role = aws_iam_role.msk_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeCluster",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData",
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DescribeGroup",
        ]
        Resource = [
          "arn:aws:kafka:${var.region}:${var.account_id}:cluster/wsc2026-msk-cluster/*",
          "arn:aws:kafka:${var.region}:${var.account_id}:topic/wsc2026-msk-cluster/*",
          "arn:aws:kafka:${var.region}:${var.account_id}:group/wsc2026-msk-cluster/*",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kafka:GetBootstrapBrokers",
          "kafka:DescribeCluster",
          "kafka:ListClusters",
          "kafka:DescribeClusterV2",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
        ]
        Resource = "arn:aws:dynamodb:${var.region}:${var.account_id}:table/wsc2026-sensor-data"
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = "arn:aws:sns:${var.region}:${var.account_id}:wsc2026-sensor-alert"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
        ]
        Resource = "arn:aws:s3:::wsc2026-sensor-alert-bucket-*/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
    ]
  })
}
