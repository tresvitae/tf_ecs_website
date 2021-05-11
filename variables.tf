variable "open_ip" {
  type = list(string)
}
variable "availability_zones" {
  description = "The AWS availability zones to create subnets in."
  type = list
}
variable "environment" {
  description = " prod / dev / test"
  type = string
}
variable "instance_type" {
  type = string
}
variable "ecs_ami" {
  description = "The AMI to seed ECS instances with."
  type = string
}
variable "max_size" {
  type = number
}
variable "min_size" {
  type = number
}
variable "desired_capacity" {
  type = number
}
variable "project_name" {
  type = string
}
variable "iam_policy_arn" {
  description = "IAM Policy to be attached to role"
  type = list(string)
}