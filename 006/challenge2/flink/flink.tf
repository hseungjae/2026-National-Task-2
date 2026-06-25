resource "aws_glue_catalog_database" "default" {
  name = "default"
}

resource "aws_glue_catalog_database" "analytics" {
  name = "real_time_analytics"
}

resource "aws_iam_role" "flink" {
  name = "gj2026-data-flink-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "kinesisanalytics.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "gj2026-data-flink-role" }
}

resource "aws_iam_role_policy_attachment" "flink_admin" {
  role       = aws_iam_role.flink.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_kinesisanalyticsv2_application" "studio" {
  name                   = "gj2026-data-flink"
  runtime_environment    = "ZEPPELIN-FLINK-3_0"
  service_execution_role = aws_iam_role.flink.arn
  application_mode       = "INTERACTIVE"

  lifecycle {
    ignore_changes = [application_configuration]
  }

  depends_on = [
    aws_iam_role_policy_attachment.flink_admin,
    aws_glue_catalog_database.default,
    aws_glue_catalog_database.analytics,
  ]

}
