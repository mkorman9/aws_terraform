output "vpc" {
  value = module.vpc.vpc_id
}

output "cluster" {
  value = aws_ecs_cluster.cluster.arn
}

output "load_balancer" {
  value = aws_lb.load_balancer.arn
}

output "ecs_role" {
  value = aws_iam_role.ecs_role.arn
}

output "task_execution_role" {
  value = aws_iam_role.task_execution_role.arn
}
