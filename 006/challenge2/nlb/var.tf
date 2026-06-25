variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for NLB"
  type        = string
}

variable "kafka_instance_id" {
  description = "Kafka EC2 instance ID"
  type        = string
}

variable "kafka_private_ip" {
  description = "Kafka EC2 private IP"
  type        = string
}
