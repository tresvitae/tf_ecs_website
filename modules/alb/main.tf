resource "aws_alb" "app" {
  name                = "web-app--alb"
  security_groups     = [aws_security_group.alb_sg.id]
  subnets             = var.subnets_id # [aws_default_subnet.default_az1.id,aws_default_subnet.default_az2.id]

  tags = {
    "Terraform" : "true"
  }
}

resource "aws_alb_target_group" "app" {
  name                = "web-app--tf"
  port                = "80"
  protocol            = "HTTP"
  vpc_id              = var.vpc # aws_default_vpc.default.id

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
  vpc_id            = var.vpc # aws_default_vpc.default.id

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