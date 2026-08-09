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

  # Tags are deliberately not set here: CreateApplication with tags fails with
  # ConcurrentModificationException ("Tags are already registered for this
  # resource ARN") whenever this app was deleted and recreated recently, since
  # AWS's tag registry takes a while to release the ARN. Tagged separately via
  # TagResource in null_resource.flink_parallelism below, per AWS's own
  # workaround suggestion in that error message.
  lifecycle {
    ignore_changes = [application_configuration]
  }

  depends_on = [aws_glue_catalog_database.default, aws_glue_catalog_database.flink]
}

data "aws_region" "current" {}

# CreateApplication rejects a CUSTOM parallelism config on INTERACTIVE (Zeppelin)
# apps at creation time (fails with an opaque UnknownError), so it's applied via
# UpdateApplication after the app exists instead - the same call the console makes
# when you change it under "크기 조정".
resource "null_resource" "flink_parallelism" {
  triggers = {
    application_name = aws_kinesisanalyticsv2_application.flink.name
  }

  provisioner "local-exec" {
    interpreter = ["powershell", "-Command"]
    command     = <<-EOT
      $ErrorActionPreference = "Stop"
      $appName = "${aws_kinesisanalyticsv2_application.flink.name}"
      $appArn  = "${aws_kinesisanalyticsv2_application.flink.arn}"
      $region  = "${data.aws_region.current.name}"

      for ($i = 0; $i -lt 30; $i++) {
        $status = aws kinesisanalyticsv2 describe-application --application-name $appName --region $region --query "ApplicationDetail.ApplicationStatus" --output text
        if ($status -eq "READY" -or $status -eq "RUNNING") { break }
        Start-Sleep -Seconds 10
      }

      $versionId = aws kinesisanalyticsv2 describe-application --application-name $appName --region $region --query "ApplicationDetail.ApplicationVersionId" --output text

      $configFile = Join-Path $env:TEMP "wsc2026-flink-parallelism-update.json"
      '{"FlinkApplicationConfigurationUpdate":{"ParallelismConfigurationUpdate":{"ConfigurationTypeUpdate":"CUSTOM","ParallelismUpdate":4,"ParallelismPerKPUUpdate":1,"AutoScalingEnabledUpdate":false}}}' | Set-Content -Path $configFile -Encoding ascii -NoNewline

      aws kinesisanalyticsv2 update-application --application-name $appName --current-application-version-id $versionId --application-configuration-update "file://$configFile" --region $region

      aws kinesisanalyticsv2 tag-resource --resource-arn $appArn --tags Key=Name,Value=$appName --region $region
    EOT
  }

  depends_on = [aws_kinesisanalyticsv2_application.flink]
}
