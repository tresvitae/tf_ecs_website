provider "aws" {
  profile = "default"
  region  = "eu-west-1"
}

# DEFAULT VPC & SUBNETS
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
    name  = "web-app"
}

resource "aws_ecs_task_definition" "softserve" {
  family                = "web-app"
  container_definitions = file("softserve.json")
}


# IAM ROLE
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
  role       = aws_iam_role.ecs_agent.name
  count      = "${length(var.iam_policy_arn)}"
  policy_arn = "${var.iam_policy_arn[count.index]}"
}

resource "aws_iam_instance_profile" "ecs_agent" {
  name                = "ecs-agent"
  role                = aws_iam_role.ecs_agent.name
}


# EC2 CLUSTER = AUTOSCALING & LAUNCH CONFIGURATION
resource "aws_launch_configuration" "launch_config" {
  image_id             = var.ecs_ami
  iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
  security_groups      = [aws_security_group.cluster_sg.id]
  instance_type        = var.instance_type
  user_data            = <<EOF
#! /bin/bash
sudo apt-get update
sudo echo "ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name}" >> /etc/ecs/ecs.config
EOF
# my-cluster (in user_data) as name of cluster /hard code only
}

resource "aws_autoscaling_group" "asg" {
  name                      = "asg"
  vpc_zone_identifier       = [aws_default_subnet.default_az1.id,aws_default_subnet.default_az2.id]
  launch_configuration      = aws_launch_configuration.launch_config.name

  desired_capacity          = var.desired_capacity
  min_size                  = var.min_size
  max_size                  = var.max_size
  health_check_grace_period = 300
  health_check_type         = "EC2"

  tag {
    key                 = "Name"
    value               = "${var.project_name}--${var.environment}--ecs"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "cluster_sg" {
  name              = "${var.project_name}--${var.environment}--cluster_sg"
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

resource "aws_security_group_rule" "internal_traffic" {
  type                     = "ingress"
  from_port                = 32768
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id        = aws_security_group.cluster_sg.id
}


# LOAD BALANCER
resource "aws_alb" "app" {
    name                = "web-app--alb"
    security_groups     = [aws_security_group.alb_sg.id]
    subnets             = [aws_default_subnet.default_az1.id,aws_default_subnet.default_az2.id]

  tags = {
    "Terraform" : "true"
  }
}

resource "aws_alb_target_group" "app" {
  name                = "web-app--tf"
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

resource "aws_alb_listener" "listener" {
  load_balancer_arn = "${aws_alb.app.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.app.arn}"
    type             = "forward"
  }
}

resource "aws_security_group" "alb_sg" {
  name              = "${var.project_name}--${var.environment}--alb-sg"
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


# SERVICE
resource "aws_ecs_service" "web_app" {
  name            = "${var.project_name}--${var.environment}--service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.softserve.arn
  desired_count   = 2
  #iam_role        = aws_iam_role.ecs_agent.arn
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  
  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.app.arn}"
    container_name   = "softserve"
    container_port   = 80
  }
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