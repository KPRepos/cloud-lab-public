#custom variables outside of modules
variable "cluster-name" {
  # default     = "eks-lab"
  type        = string
  description = "The name of your EKS Cluster"
}

variable "nodegroup-name" {
  # default     = "eks-lab"
  type        = string
  description = "The name of your EKS Node Group"
  default     = "ng1"
}

variable "deploy_pod_service_account" {
  # default     = "eks-lab"
  type        = string
  description = "deploy a sample Pos SA ?"
}


variable "sample_pod_service_account_name" {
  # default     = "eks-lab"
  type        = string
  description = "The name of your sample_pod_service_account"
}


variable "region" {
  # default     = "us-west-2"
  type        = string
  description = "The AWS Region to deploy EKS"
}

variable "instance_types" {
  type    = list(any)
  default = ["t3.small"]
}

variable "capacity_type" {
  type        = string
  description = "SPOT"
}


variable "cluster_endpoint_public_access" {
  type        = string
  description = "true or false"
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {

  type = list(any)

}

variable "deploy_eks_alb_controller" {
  type = string
}

variable "env_name" {
  # default     = "us-west-2"
  type        = string
  description = "The environment key to append to resources"
}

variable "min_size" {
  type = string
}

variable "max_size" {
  type = string
}

variable "desired_size" {
  type = string
}



variable "enable_karpenter" {
  type        = string
  description = "version"
  default     = "false"
}

variable "cluster_version" {
  type = string
}
