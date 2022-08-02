variable "environment" {
  description = "Environment name"
  type        = string
}

variable "profile" {
  description = "Profile name to pass to the app (by default: prd)"
  type        = string
  default     = "prd"
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

variable "image" {
  description = "URL of Docker image (default: 778189968080.dkr.ecr.eu-central-1.amazonaws.com/kotlin-vertx:1)"
  type        = string
  default     = "778189968080.dkr.ecr.eu-central-1.amazonaws.com/kotlin-vertx:1"
}

variable "memory" {
  description = "Amount of memory to assign to app container (default: 300 MiB)"
  type        = number
  default     = 300
}

variable "instances_count" {
  description = "Number of instances of the app to deploy across the cluster (by default: 1)"
  type        = number
  default     = 1
}
