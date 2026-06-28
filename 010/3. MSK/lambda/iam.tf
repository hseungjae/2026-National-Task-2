resource "aws_iam_role" "function" {
  name = "${var.prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "function" {
  name = "${var.prefix}-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Allow"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = [
          var.dynamodb_table_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "function" {
  role       = aws_iam_role.function.name
  policy_arn = aws_iam_policy.function.arn
}

resource "aws_iam_role_policy_attachment" "execute" {
  role       = aws_iam_role.function.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}

resource "aws_iam_role_policy" "msk_access" {
  name = "${var.prefix}-lambda-msk-access"
  role = aws_iam_role.function.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "MSKClusterAccess"
        Effect = "Allow"
        Action = [
          "kafka:DescribeClusterV2",
          "kafka:GetBootstrapBrokers",
          "kafka:ListScramSecrets",
          "kafka-cluster:Connect"
        ]
        Resource = [var.msk_cluster_arn]
      },
      {
        Sid    = "MSKGroupOperations"
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DescribeGroup"
        ]
        Resource = ["${replace(var.msk_cluster_arn, ":cluster/", ":group/")}/*"]
      },
      {
        Sid    = "MSKTopicOperations"
        Effect = "Allow"
        Action = [
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]
        Resource = ["${replace(var.msk_cluster_arn, ":cluster/", ":topic/")}/order-events"]
      },
      {
        Sid    = "EC2DescribeOperations"
        Effect = "Allow"
        Action = [
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeNetworkInterfaces"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "EC2NetworkInterfaceOperations"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = ["*"]
        Condition = {
          StringEqualsIfExists = {
            "ec2:SubnetID" = var.private_subnets
          }
        }
      }
    ]
  })
}
