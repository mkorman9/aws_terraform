output "app_role" {
  value = aws_iam_role.app_role.arn
}

output "db" {
  value = aws_db_instance.db.arn
}
