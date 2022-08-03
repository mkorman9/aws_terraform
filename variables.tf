variable "environment" {
  description = "Environment name"
  type        = string
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

variable "instance_max_cpu" {
  description = "Threshold for max CPU usage"
  type        = number
  default     = 85
}
