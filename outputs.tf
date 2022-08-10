output "vpc" {
  value = module.vpc.vpc_id
}

output "cluster" {
  value = aws_ecs_cluster.cluster.arn
}
