variable "project_name" {
  type = string
}
variable "environment" {
  description = " prod / dev / test"
  type = string
}
variable "open_ip" {
  type = list(string)
}
variable "vpc" {
  type = string
}
variable "subnets_id" {
  type = list(string)
}