variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region. For example: eu-central-1"
  type        = string
}

variable "db_instance_class" {
  description = "Instance class for RDS (default: db.t3.micro)"
  type        = string
  default     = "db.t3.micro"
}
