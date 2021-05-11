variable "project_name" {
  type = string
}
variable "environment" {
  description = " prod / dev / test"
  type = string
}
variable "cluster_id" {
  type = string
}
variable "target_group" {
  type = string
}
variable "task_arn" {
  type = string
}