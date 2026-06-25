output "flink_application_name" {
  value = aws_kinesisanalyticsv2_application.studio.name
}

output "glue_database_name" {
  value = aws_glue_catalog_database.analytics.name
}
