locals {
  keycloak_issuer_url        = "https://${var.keycloak_domain}/realms/team"
  keycloak_condition_prefix  = "${var.keycloak_domain}/realms/team"
}

resource "aws_iam_openid_connect_provider" "keycloak" {
  url = local.keycloak_issuer_url

  client_id_list = [
    "gj2026-keycloak-dev",
    "gj2026-keycloak-sec"
  ]

  thumbprint_list = [
    "0000000000000000000000000000000000000000"
  ]

  tags = { Name = "gj2026-keycloak-oidc" }

  lifecycle {
    ignore_changes = [thumbprint_list]
  }
}

resource "aws_iam_policy" "dev_team" {
  name = "gj2026-keycloak-dev-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/team" = "dev-team"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "dev_team" {
  name = "gj2026-keycloak-dev-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = aws_iam_openid_connect_provider.keycloak.arn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.keycloak_condition_prefix}:aud" = "gj2026-keycloak-dev"
          }
        }
      }
    ]
  })

  tags = {
    Name = "gj2026-keycloak-dev-role"
    team = "dev-team"
  }
}

resource "aws_iam_role_policy_attachment" "dev_team" {
  role       = aws_iam_role.dev_team.name
  policy_arn = aws_iam_policy.dev_team.arn
}

resource "aws_iam_policy" "sec_team" {
  name = "gj2026-keycloak-sec-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/team" = "sec-team"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeNetworkInterfaces"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "sec_team" {
  name = "gj2026-keycloak-sec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = aws_iam_openid_connect_provider.keycloak.arn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.keycloak_condition_prefix}:aud" = "gj2026-keycloak-sec"
          }
        }
      }
    ]
  })

  tags = {
    Name = "gj2026-keycloak-sec-role"
    team = "sec-team"
  }
}

resource "aws_iam_role_policy_attachment" "sec_team" {
  role       = aws_iam_role.sec_team.name
  policy_arn = aws_iam_policy.sec_team.arn
}
