resource "aws_iam_role" "nosql_client" {
  name = "skills-nosql-client-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "nosql_client" {
  name = "skills-nosql-client-policy"
  role = aws_iam_role.nosql_client.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource = var.secret_arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "nosql_client" {
  name = "skills-nosql-client-profile"
  role = aws_iam_role.nosql_client.name
}
