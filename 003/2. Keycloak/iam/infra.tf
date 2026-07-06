resource "aws_iam_policy" "infra" {
  name        = "${var.prefix}-infra-policy"
  description = "Infra team: full read + EC2 start/stop except protected instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadOnlyAllRegions"
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:Get*",
          "ec2:List*",
          "s3:List*",
          "s3:Get*",
          "iam:Get*",
          "iam:List*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowStartStopUnlessProtected"
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:ResourceTag/protected" = "true"
          }
        }
      },
      {
        Sid    = "ExplicitDenyProtected"
        Effect = "Deny"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/protected" = "true"
          }
        }
      }
    ]
  })

  tags = { Team = "infra" }
}

resource "aws_iam_role" "infra" {
  name                 = "${var.prefix}-infra-role"
  description          = "SAML federation role for infra-team"
  assume_role_policy   = local.saml_trust_policy
  max_session_duration = 28800

  tags = { Team = "infra" }
}

resource "aws_iam_role_policy_attachment" "infra" {
  role       = aws_iam_role.infra.name
  policy_arn = aws_iam_policy.infra.arn
}