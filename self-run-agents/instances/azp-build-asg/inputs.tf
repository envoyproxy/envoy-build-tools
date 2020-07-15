variable "ami_prefix" { type = string }
variable "aws_account_id" { type = string }
variable "azp_pool_name" { type = string }
variable "azp_token" { type = string }
variable "disk_size_gb" { type = number }
variable "on_demand_instances_count" {
  type    = number
  default = 0
}
variable "idle_instances_count" { type = number }
variable "instance_type" { type = string }
variable "bazel_cache_bucket" { type = string }
variable "cache_prefix" { type = string }
