locals {
    app_service_name = "${var.environment}-app"
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

/*
  ACM
*/
resource "aws_acm_certificate" "app_cert" {
  domain_name       = var.app_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Environment = var.environment
  }
}

// OR
/*
data "aws_acm_certificate" "amazon_issued" {
  domain      = var.app_domain
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}
*/

/*
  EC2
*/
resource "aws_lb" "app_load_balancer" {
  name               = "${var.environment}-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_sg.id]
  subnets            = module.vpc.public_subnets

  tags = {
    Environment = var.environment
  }
}

resource "aws_lb_listener" "app_load_balancer_listener_80" {
  load_balancer_arn = aws_lb.app_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      status_code  = "HTTP_301"
      protocol     = "HTTPS"
      port         = "443"
    }
  }
}

resource "aws_lb_listener" "app_load_balancer_listener_443" {
  load_balancer_arn = aws_lb.app_load_balancer.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.app_cert.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      status_code  = "404"
      content_type = "application/json"
      message_body = jsonencode({
        status = "error"
        message = "not found"
      })
    }
  }
}

resource "aws_lb_target_group" "app_target_group" {
  name        = "${var.environment}-app-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = module.vpc.vpc_id

  health_check {
    enabled  = true
    protocol = "HTTP"
    path     = "/health"
    matcher  = "200"
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_lb_listener_rule" "app_listener_rule_443" {
  depends_on = [
    aws_lb_target_group.app_target_group
  ]

  listener_arn = aws_lb_listener.app_load_balancer_listener_443.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

/*
    CloudWatch
*/
resource "aws_cloudwatch_log_group" "app_log_group" {
  name = "/${var.environment}-logs/app"
}

resource "aws_cloudwatch_metric_alarm" "app_cpu_high" {
  depends_on = [
    aws_ecs_service.app_service
  ]

  alarm_name          = "${var.environment}-app-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "75"

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = local.app_service_name
  }

  alarm_actions = [aws_appautoscaling_policy.app_scale_up_policy.arn]

  tags = {
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "app_cpu_low" {
  depends_on = [
    aws_ecs_service.app_service
  ]

  alarm_name          = "${var.environment}-app-cpu-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "10"

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = local.app_service_name
  }

  alarm_actions = [aws_appautoscaling_policy.app_scale_down_policy.arn]

  tags = {
    Environment = var.environment
  }
}

resource "aws_appautoscaling_policy" "app_scale_up_policy" {
  depends_on = [
    aws_appautoscaling_target.app_scale_target
  ]

  name               = "${var.environment}-app-scale-up-policy"
  service_namespace  = "ecs"
  resource_id        = "service/${local.cluster_name}/${local.app_service_name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "app_scale_down_policy" {
  depends_on = [
    aws_appautoscaling_target.app_scale_target
  ]

  name               = "${var.environment}-app-scale-down-policy"
  service_namespace  = "ecs"
  resource_id        = "service/${local.cluster_name}/${local.app_service_name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

resource "aws_appautoscaling_target" "app_scale_target" {
  depends_on = [
    aws_ecs_service.app_service
  ]

  service_namespace  = "ecs"
  resource_id        = "service/${local.cluster_name}/${local.app_service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.app_min_instances
  max_capacity       = var.app_max_instances
}

/*
    ECS
*/
resource "aws_ecs_task_definition" "app_task_definition" {
  family                   = "${var.environment}-app"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  memory                   = 300

  task_role_arn      = aws_iam_role.app_role.arn
  execution_role_arn = aws_iam_role.task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = var.app_image
      essential = true

      portMappings = [
        {
          containerPort = 8080
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group  = aws_cloudwatch_log_group.app_log_group.name
          awslogs-region = var.aws_region
        }
      }

      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "app_service" {
  name                = local.app_service_name
  cluster             = aws_ecs_cluster.cluster.id
  task_definition     = aws_ecs_task_definition.app_task_definition.arn
  launch_type         = "EC2"
  scheduling_strategy = "REPLICA"

  desired_count                      = var.app_desired_instances
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_target_group.id
    container_name   = "app"
    container_port   = 8080
  }

  tags = {
    Environment = var.environment
  }
}
