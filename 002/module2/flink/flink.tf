resource "aws_security_group" "flink" {
  name        = "wsc2026-analytics-flink-sg"
  description = "Security group for Flink Studio"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "wsc2026-analytics-flink-sg" }
}

resource "aws_glue_catalog_database" "default" {
  name = "default"
}

resource "aws_glue_catalog_database" "flink" {
  name = "wsc2026-analytics-db"
}

resource "aws_kinesisanalyticsv2_application" "flink" {
  name                   = "wsc2026-analytics-flink"
  runtime_environment    = "ZEPPELIN-FLINK-3_0"
  service_execution_role = var.flink_role_arn
  application_mode       = "INTERACTIVE"

  lifecycle {
    ignore_changes = [application_configuration]
  }

  depends_on = [aws_glue_catalog_database.default, aws_glue_catalog_database.flink]

  tags = { Name = "wsc2026-analytics-flink" }
}
