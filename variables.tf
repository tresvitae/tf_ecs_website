variable "open_ip" {
  type = list(string)
}
variable "availability_zones" {
  description = "The AWS availability zones to create subnets in."
  type = list
}
variable "instance_prod" {
  type = string
}
variable "instance_test" {
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