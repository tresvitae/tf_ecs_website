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
  name = "${var.project_name}-${(terraform.workspace == "prod" ? "prod" : "test")}--my-cluster"

  tags = {
    "Terraform" : "true"
  }
}

resource "aws_ecr_repository" "web_app" {
    name  = (terraform.workspace == "prod" ? "web-app" : "web-test")
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
  name               = (terraform.workspace == "prod" ? "ecs-agent" : "ecs-agent-test")
  assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
}

resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role       = aws_iam_role.ecs_agent.name
  count      = "${length(var.iam_policy_arn)}"
  policy_arn = "${var.iam_policy_arn[count.index]}"
}

resource "aws_iam_instance_profile" "ecs_agent" {
  name                = (terraform.workspace == "prod" ? "ecs-agent" : "ecs-agent-test")
  role                = aws_iam_role.ecs_agent.name
}


# EC2 CLUSTER = AUTOSCALING & LAUNCH CONFIGURATION
resource "aws_launch_configuration" "launch_config" {
  image_id             = var.ecs_ami
  iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
  security_groups      = [aws_security_group.cluster_sg.id]
  instance_type        = (terraform.workspace == "prod" ? var.instance_prod : var.instance_test)
  user_data            = <<EOF
#! /bin/bash
sudo apt-get update
sudo echo "ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name}" >> /etc/ecs/ecs.config
EOF
# my-cluster (in user_data) as name of cluster /hard code only
}

resource "aws_autoscaling_group" "asg" {
  name                      = "${var.project_name}-${(terraform.workspace == "prod" ? "prod" : "test")}-asg"
  vpc_zone_identifier       = [aws_default_subnet.default_az1.id,aws_default_subnet.default_az2.id]
  launch_configuration      = aws_launch_configuration.launch_config.name

  desired_capacity          = var.desired_capacity
  min_size                  = var.min_size
  max_size                  = var.max_size
  health_check_grace_period = 300
  health_check_type         = "EC2"

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${(terraform.workspace == "prod" ? "prod" : "test")}--ecs"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "cluster_sg" {
  name              = "${var.project_name}-${(terraform.workspace == "prod" ? "prod" : "test")}--cluster-sg"
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
  source_security_group_id = module.alb.sg_id # aws_security_group.alb_sg.id
  security_group_id        = aws_security_group.cluster_sg.id
}

module "alb" {
  source = "./modules/alb"

  project_name = var.project_name
  open_ip = var.open_ip

  vpc = aws_default_vpc.default.id
  subnets_id = [aws_default_subnet.default_az1.id,aws_default_subnet.default_az2.id]
}

module "service" {
  source = "./modules/service"

  project_name = var.project_name

  cluster_id = aws_ecs_cluster.ecs_cluster.id
  target_group = module.alb.tg_arn # "${aws_alb_target_group.app.arn}"
  task_arn = aws_ecs_task_definition.softserve.arn
}