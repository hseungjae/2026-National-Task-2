data "aws_iam_policy_document" "keda_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_arn, "/^.*oidc-provider\\//", "")}:sub"
      values   = ["system:serviceaccount:keda:keda-operator"]
    }
  }
}

resource "aws_iam_role" "keda_role" {
  name               = "${var.prefix}-keda-operator-role"
  assume_role_policy = data.aws_iam_policy_document.keda_assume.json
}

resource "aws_iam_policy" "keda_sqs_policy" {
  name = "${var.prefix}-keda-operator-sqs-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Statement1"
        Effect = "Allow"
        Action = [
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = var.queue_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "keda_sqs" {
  role       = aws_iam_role.keda_role.name
  policy_arn = aws_iam_policy.keda_sqs_policy.arn
}
