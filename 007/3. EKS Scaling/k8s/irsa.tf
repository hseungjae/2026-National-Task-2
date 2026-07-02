locals {
  oidc_host = replace(var.cluster_oidc_issuer_url, "https://", "")
}

resource "aws_iam_role" "order_sa_role" {
  name = "${var.prefix}-order-sa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_host}:sub" = "system:serviceaccount:skillsmkt:order-sa"
          "${local.oidc_host}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "order_sa_sqs" {
  role       = aws_iam_role.order_sa_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}
