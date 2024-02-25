
variable "region" {
  # default     = "us-west-2"
  type        = string
  description = "The AWS Region to deploy EKS"
}

variable "worker_instance_type" {
  type    = string
  default = "t3.small"
}

variable "control_panel_instance_type" {
  type    = string
  default = "t3.small"
}


variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "allowed_cidrs_k8_public_dns" {
  type    = list(any)
  default = []
}

variable "add_user_local_ip_to_lb" {
  type        = bool
  default     = "true"
  description = "true/false"
}


variable "capacity_type" {
  type        = string
  description = "SPOT"
}

variable "worker_nodes_count" {
  type        = number
  description = "count"
}


variable "ami_id" {
  type        = string
  description = "Node AMI ID"
  default     = "NA"
}

variable "env_name" {
  # default     = "us-west-2"
  type        = string
  description = "The environment key to append to resources"
}

#For Future

variable "domain_name" {
  description = "The domain name for the hosted zone."
  type        = string
  default     = "k8.local"
}

variable "enable_k8_api_public" {
  type        = bool
  description = "true/false"
  default     = "true"
}

