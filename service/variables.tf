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

variable "desired_instances" {
  description = "Number of instances of the app to deploy across the cluster (by default: 1)"
  type        = number
  default     = 1
}

variable "min_instances" {
  description = "Minimal number of instances of the app (by default: 1)"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximal number of instances of the app (by default: 1)"
  type        = number
  default     = 1
}

variable "autoscaling_max_cpu" {
  description = "Threshold for max CPU usage"
  type        = string
  default     = "75"
}

variable "autoscaling_min_cpu" {
  description = "Threshold for min CPU usage"
  type        = string
  default     = "10"
}

variable "autoscaling_max_cpu_eval_period" {
  description = "The number of periods over which data is compared to the specified threshold for max cpu metric alarm"
  type        = string
  default     = "3"
}

variable "autoscaling_min_cpu_eval_period" {
  description = "The number of periods over which data is compared to the specified threshold for min cpu metric alarm"
  type        = string
  default     = "3"
}

variable "autoscaling_max_cpu_period" {
  description = "The period in seconds over which the specified statistic is applied for max cpu metric alarm"
  type        = string
  default     = "60"
}
variable "autoscaling_min_cpu_period" {
  description = "The period in seconds over which the specified statistic is applied for min cpu metric alarm"
  type        = string
  default     = "60"
}
