output "nlb_dns_name" {
  value = aws_lb.kafka.dns_name
}

output "nlb_arn" {
  value = aws_lb.kafka.arn
}
