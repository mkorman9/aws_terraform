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
