variable "open_ip" {
  type = list(string)
}

provider "aws" {
  profile = "default"
  region = "eu-west-1"
}

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

resource "aws_security_group" "prod_web" {
  name            = "prod_web"
  description     = "Allow standard htttp and https prots inbound and everything outbound"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.open_ip
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.open_ip
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.open_ip
  }

  tags = {
    "Terraform" : "true"
  }
}