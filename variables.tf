variable "environment" {
  description = "Environment name"
  type        = string
}

variable "profile" {
  description = "Profile of the environment - dev/test/prd (by default: prd)"
  type        = string
  default     = "prd"
}


variable "aws_region" {
  description = "AWS region. For example: eu-central-1"
  type        = string
}


variable "instance_type" {
  description = "Type of instance inside Autoscaling group. By default: t2.micro"
  type        = string
  default     = "t2.micro"
}

variable "min_instances" {
  description = "The minimal instance count in the cluster"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "The maximal instance count in the cluster"
  type        = number
  default     = 1
}

variable "desired_instances" {
  description = "The desired instance count in the cluster"
  type        = number
  default     = 1
}

variable "app_db_instance_class" {
  description = "Instance class for RDS (default: db.t3.micro)"
  type        = string
  default     = "db.t3.micro"
}

variable "app_image" {
  description = "URL of Docker image (default: 778189968080.dkr.ecr.eu-central-1.amazonaws.com/kotlin-vertx:1)"
  type        = string
  default     = "778189968080.dkr.ecr.eu-central-1.amazonaws.com/kotlin-vertx:1"
}

variable "app_desired_instances" {
  description = "Number of instances of the app to deploy across the cluster (by default: 1)"
  type        = number
  default     = 1
}

variable "app_min_instances" {
  description = "Minimal number of instances of the app (by default: 1)"
  type        = number
  default     = 1
}

variable "app_max_instances" {
  description = "Maximal number of instances of the app (by default: 1)"
  type        = number
  default     = 1
}

variable "app_domain" {
  description = "Domain name to use in app's load balancer"
  type        = string
}
