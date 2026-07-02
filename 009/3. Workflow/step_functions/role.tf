resource "aws_iam_role" "sfn_role" {
  name = "workflow-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          "Service": ["states.amazonaws.com"]
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.sfn_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}