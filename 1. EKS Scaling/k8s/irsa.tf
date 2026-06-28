data "aws_iam_policy_document" "worker_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_arn, "/^.*oidc-provider\\//", "")}:sub"
      values   = ["system:serviceaccount:wsi-app:wsi-worker-sa"]
    }
  }
}

resource "aws_iam_role" "worker_role" {
  name               = "${var.prefix}-worker-role"
  assume_role_policy = data.aws_iam_policy_document.worker_assume.json
}

resource "aws_iam_role_policy_attachment" "worker_sqs" {
  role       = aws_iam_role.worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "kubernetes_service_account" "worker_sa" {
  metadata {
    name      = "wsi-worker-sa"
    namespace = kubernetes_namespace.wsi_app.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.worker_role.arn
    }
  }
    depends_on = [ kubernetes_namespace.wsi_app ]
}
