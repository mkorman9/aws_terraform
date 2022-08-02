data "aws_vpc" "vpc" {
  filter {
    name = "tag:Environment"
    values = [var.environment]
  }
}

data "aws_subnet_ids" "subnets" {
  vpc_id = data.aws_vpc.vpc.id
}

data "aws_ecs_cluster" "cluster" {
  cluster_name = "${var.environment}-cluster"
}

data "aws_lb" "load_balancer" {
  name = "${var.environment}-lb"
  tags = {
    Environment = var.environment
  }
}

data "aws_lb_listener" "load_balancer_listener_80" {
  load_balancer_arn = data.aws_lb.load_balancer.arn
  port = 80
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

/*
    RDS
*/
resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       =  "${var.environment}-db-subnet-group"
  subnet_ids = data.aws_subnet_ids.subnets.ids

  tags = {
    Environment = var.environment
  }
}

resource "aws_security_group" "db_sg" {
  name   = "${var.environment}-db-sg"
  vpc_id = data.aws_vpc.vpc.id

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_db_instance" "db" {
  allocated_storage      = 10
  engine                 = "postgres"
  engine_version         = "13.3"
  instance_class         = var.db_instance_class
  username               = "postgres"
  password               = random_password.db_password.result
  db_name                = "postgres"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  tags = {
    Environment = var.environment
  }
}

/*
    Secrets Manager
*/
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.environment}-db-credentials"
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = aws_db_instance.db.username
    password = aws_db_instance.db.password
    database = aws_db_instance.db.db_name
    host = aws_db_instance.db.address
    port = aws_db_instance.db.port
  })
}

/*
  EC2
*/
resource "aws_lb_target_group" "target_group" {
  name     = "${var.environment}-app-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.vpc.id

  tags = {
    Environment = var.environment
  }
}

resource "aws_lb_listener_rule" "listener_rule_80" {
  listener_arn = data.aws_lb_listener.load_balancer_listener_80.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
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
resource "aws_cloudwatch_log_group" "log_group" {
  name = "${var.environment}-logs/app"
}

/*
    ECS
*/
resource "aws_ecs_task_definition" "task_definition" {
  family                   = "${var.environment}-app"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  memory                   = var.memory

  task_role_arn = aws_iam_role.app_role.arn
  execution_role_arn = data.aws_iam_role.task_execution_role.arn

  container_definitions = jsonencode([
    {
      name = "app"
      image = var.image
      essential = true
      memory = var.memory

      portMappings = [
        {
          containerPort = 8080
          hostPort = 0
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = aws_cloudwatch_log_group.log_group.name
          awslogs-region = var.aws_region
        }
      }

      healthCheck = {
        command = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
        interval = 30
        timeout = 5
        retries = 3
        startPeriod = 30
      }

      environment = [
        {
         name = "ENVIRONMENT_NAME"
         value = var.environment
        },
        {
          name = "PROFILE"
          value = var.profile
        },
        {
          name = "SERVER_HOST"
          value = "0.0.0.0"
        },
        {
          name = "SERVER_PORT"
          value = "8080"
        },
        {
          name = "DB_URI"
          value = "jdbc:postgresql://${aws_db_instance.db.address}:${aws_db_instance.db.port}/${aws_db_instance.db.db_name}"
        }
      ]
      secrets = [
        {
          name = "DB_USER"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:username::"
        },
        {
          name = "DB_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:password::"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "service" {
  name            = "${var.environment}-app"
  cluster         = data.aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = var.instances_count
  iam_role        = data.aws_iam_role.ecs_role.arn

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.id
    container_name   = "app"
    container_port   = 8080
  }

  tags = {
    Environment = var.environment
  }
}
