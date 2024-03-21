
variable "project_id" {
  description = "The ID of the project where VPC and subnets will be created."
  type        = string
  default     = ""
}

variable "region" {
  description = "The region where subnets will be created."
  type        = string
  default     = "us-west1"
}


variable "vpc_name" {
  description = "VPC Name"
  type        = string
}

variable "enable_cloud_nat" {
  type    = string
  default = "false"
}

variable "env_name" {
  description = "The name of the cluster"
  type        = string
}
