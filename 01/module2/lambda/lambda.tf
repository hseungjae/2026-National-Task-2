# ── Lambda 실행 역할 ─────────────────────────────────────────────────────────
resource "aws_iam_role" "db_client_role" {
  name = "wsc2026-db-client-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "db_client_policy" {
  name = "wsc2026-db-client-policy"
  role = aws_iam_role.db_client_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.secret_arn
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"]
        Resource = "*"
      }
    ]
  })
}

# ── Lambda 함수 (RDS Proxy 경유 MySQL 접속) ──────────────────────────────────
# scripts/build-lambda-zip.sh 로 미리 빌드된 zip(pymysql 포함)을 배포
resource "aws_lambda_function" "db_client" {
  function_name    = var.function_name
  role             = aws_iam_role.db_client_role.arn
  handler          = "lambda_db_client.lambda_handler"
  runtime          = "python3.14"
  filename         = "${path.module}/../lambda_db_client.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda_db_client.zip")
  timeout          = 30

  environment {
    variables = {
      SECRET_NAME = var.secret_name
    }
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.sg_id]
  }

  depends_on = [aws_iam_role_policy.db_client_policy]
}
