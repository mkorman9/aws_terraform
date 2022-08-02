data "aws_ecs_cluster" "cluster" {
  cluster_name = "${var.environment}-cluster"
}

data "aws_lb" "load_balancer" {
  name = "${var.environment}-lb"
  tags = {
    Environment = var.environment
  }
}

data "aws_iam_role" "ecs_role" {
  name = "${var.environment}-ecs-role"
}

data "aws_iam_role" "task_execution_role" {
  name = "${var.environment}-task-execution-role"
}

/*
    IAM
*/
data "template_file" "app_role" {
  template = file("${path.module}/policies/app_role.json")
}

resource "aws_iam_role" "app_role" {
  name               = "${var.environment}-app-role"
  assume_role_policy = data.template_file.app_role.rendered
}

data "template_file" "app_role_policy" {
  template = file("${path.module}/policies/app_role_policy.json")
}

resource "aws_iam_role_policy" "app_role_policy" {
  name   = "${var.environment}-app-role-policy"
  role   = aws_iam_role.app_role.name
  policy = data.template_file.app_role_policy.rendered
}
