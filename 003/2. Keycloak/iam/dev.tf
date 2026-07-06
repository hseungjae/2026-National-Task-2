resource "aws_iam_policy" "dev" {
  name        = "${var.prefix}-dev-policy"
  description = "Dev team: read-only EC2/S3 in Seoul region"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SeoulRegionReadOnly"
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:Get*",
          "ec2:List*",
          "s3:List*",
          "s3:Get*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "ap-northeast-2"
          }
        }
      }
    ]
  })

  tags = { Team = "dev" }
}

resource "aws_iam_role" "dev" {
  name                 = "${var.prefix}-dev-role"
  description          = "SAML federation role for dev-team"
  assume_role_policy   = local.saml_trust_policy
  max_session_duration = 28800

  tags = { Team = "dev" }
}

resource "aws_iam_role_policy_attachment" "dev" {
  role       = aws_iam_role.dev.name
  policy_arn = aws_iam_policy.dev.arn
}