locals {
    cluster_name = "${var.environment}-cluster"
}

/*
    VPC
*/
data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "${var.environment}-vpc"

  cidr = "10.0.0.0/16"

  azs            = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  public_subnets = ["10.0.0.0/18", "10.0.64.0/18"]

  enable_nat_gateway = false

  tags = {
    Environment = var.environment
  }
}

resource "aws_security_group" "load_balancer_sg" {
  name   = "${var.environment}-load-balancer-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
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

resource "aws_security_group" "instance_sg" {
  name   = "${var.environment}-instance-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    security_groups = [aws_security_group.load_balancer_sg.id]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    security_groups = [aws_security_group.bastion_sg.id]
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

resource "aws_security_group" "bastion_sg" {
  name   = "${var.environment}-bastion-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
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

/*
    IAM
*/
data "template_file" "instance_profile" {
  template = file("${path.module}/policies/instance_profile.json")
}

resource "aws_iam_role" "instance_profile" {
  name               = "${var.environment}-instance-profile"
  assume_role_policy = data.template_file.instance_profile.rendered
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.environment}-instance-profile"
  role = aws_iam_role.instance_profile.name
}

data "template_file" "instance_profile_policy" {
  template = file("${path.module}/policies/instance_profile_policy.json")
}

resource "aws_iam_role_policy" "instance_profile_policy" {
  name   = "${var.environment}-instance-profile-policy"
  role   = aws_iam_role.instance_profile.name
  policy = data.template_file.instance_profile_policy.rendered
}

data "template_file" "task_execution_role" {
  template = file("${path.module}/policies/task_execution_role.json")
}

resource "aws_iam_role" "task_execution_role" {
  name               = "${var.environment}-task-execution-role"
  assume_role_policy = data.template_file.task_execution_role.rendered
}

data "template_file" "task_execution_role_policy" {
  template = file("${path.module}/policies/task_execution_role_policy.json")
}

resource "aws_iam_role_policy" "task_execution_role_policy" {
  name   = "${var.environment}-task-execution-role-policy"
  role   = aws_iam_role.task_execution_role.name
  policy = data.template_file.task_execution_role_policy.rendered
}

/*
    ECS
*/
resource "aws_ecs_cluster" "cluster" {
  name = local.cluster_name
}

/*
    EC2
*/
data "aws_ami" "optimized_ecs_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["591542846629"]  // AWS
}

data "template_file" "instance_user_data" {
  template = file("${path.module}/templates/instance_user_data.tpl")

  vars = {
    ecs_cluster_name = local.cluster_name
  }
}

resource "aws_launch_configuration" "launch_configuration" {
  security_groups = [aws_security_group.instance_sg.id]
  image_id        = data.aws_ami.optimized_ecs_ami.id

  user_data            = data.template_file.instance_user_data.rendered
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "autoscaling_group" {
  name                      = "${var.environment}-autoscaling-group"
  vpc_zone_identifier       = module.vpc.public_subnets
  min_size                  = var.min_instances
  max_size                  = var.max_instances
  desired_capacity          = var.desired_instances
  health_check_grace_period = 300
  launch_configuration      = aws_launch_configuration.launch_configuration.name
}

resource "aws_autoscaling_policy" "autoscaling_group_policy" {
  name                   = "${var.environment}-autoscaling-group-policy"
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.autoscaling_group.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 75.0
  }
}
