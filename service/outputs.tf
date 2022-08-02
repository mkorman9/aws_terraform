output "app_role" {
  value = aws_iam_role.app_role.arn
}

output "db" {
  value = aws_db_instance.db.arn
}

output "service" {
  value = aws_ecs_service.service.id
}

output "endpoint_http" {
  value = "http://${data.aws_lb.load_balancer.dns_name}/api/"
}
