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

