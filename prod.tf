provider "aws" {
  profile = "default"
  region  = "eu-west-1"
}

# VPC SUBNETS
resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "eu-west-1a"
  tags = {
    "Terraform" : "true"
  }
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = "eu-west-1b"
  tags = {
    "Terraform" : "true"
  }
}


# CLUSTER & TASK DEFINITION
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "my-cluster"

  tags = {
    "Terraform" : "true"
  }
}

resource "aws_ecr_repository" "web_app" {
    name  = "web_app"
}

resource "aws_ecs_task_definition" "softserve" {
  family                = "web_app"
  container_definitions = file("softserve.json")
}


# Set IAM role
data "aws_iam_policy_document" "ecs_agent" {
  statement {
    actions       = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_agent" {
  name               = "ecs-agent"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
}

resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role                = aws_iam_role.ecs_agent.name
  policy_arn          = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_agent" {
  name                = "ecs-agent"
  role                = aws_iam_role.ecs_agent.name
}


# Set EC2 with autoscaling group
resource "aws_launch_configuration" "ecs_launch_config" {
  image_id             = var.ecs_ami
  iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
  security_groups      = [aws_security_group.ecs_sg.id]
  user_data            = "#!/bin/bash\n echo ECS_CLUSTER=my-cluster >> /etc/ecs/ecs.config"
# my-cluster (in user_data) as name of cluster /hard code only
  instance_type        = var.instance_type
}

resource "aws_autoscaling_group" "failure_analysis_ecs_asg" {
  name                      = "asg"
  vpc_zone_identifier       = [aws_default_subnet.default_az1.id,aws_default_subnet.default_az2.id]
  launch_configuration      = aws_launch_configuration.ecs_launch_config.name

  desired_capacity          = var.desired_capacity
  min_size                  = var.min_size
  max_size                  = var.max_size
  health_check_grace_period = 300
  health_check_type         = "EC2"
}

resource "aws_security_group" "ecs_sg" {
  name              = "${var.project_name}--${var.environment}--sg_ecs"
  vpc_id            = aws_default_vpc.default.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = var.open_ip
  }
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = var.open_ip
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = var.open_ip
  }

  tags = {
    "Terraform" : "true"
  }
}


# LOAD BALANCER
resource "aws_alb" "ecs-load-balancer" {
    name                = "ecs-alb"
    security_groups     = [aws_security_group.ecs_sg.id]
    subnets             = [aws_default_subnet.default_az1.id,aws_default_subnet.default_az2.id]

  tags = {
    "Terraform" : "true"
  }
}

resource "aws_alb_target_group" "ecs-target-group" {
  name                = "ecs-target-group"
  port                = "80"
  protocol            = "HTTP"
  vpc_id              = aws_default_vpc.default.id

  health_check {
    healthy_threshold   = "5"
    unhealthy_threshold = "2"
    interval            = "30"
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = "5"
  }

  tags = {
    "Terraform" : "true"
  }
}

resource "aws_alb_listener" "alb-listener" {
    load_balancer_arn = "${aws_alb.ecs-load-balancer.arn}"
    port              = "80"
    protocol          = "HTTP"

    default_action {
        target_group_arn = "${aws_alb_target_group.ecs-target-group.arn}"
        type             = "forward"
    }
}

resource "aws_security_group" "alb_sg" {
  name              = "${var.project_name}--${var.environment}--sg_alb"
  vpc_id            = aws_default_vpc.default.id

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = var.open_ip
  }

  tags = {
    "Terraform" : "true"
  }
}

resource "aws_security_group_rule" "instance_in_alb" {
  type                     = "ingress"
  from_port                = 32768
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_sg.id
  security_group_id        = aws_security_group.alb_sg.id
}


# SERVICE
resource "aws_ecs_service" "web_app" {
  name            = "${var.project_name}--${var.environment}--service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.softserve.arn
  desired_count   = 2
  # LOAD BALANCER??????? load_balancer {}
}

/*
TODO:
module "cluster" {
  source             = "./modules/cluster"
}

module "service" {
  source = "./modules/service"
}

module "elb" {
  source = "./modules/elb"
}

*/
