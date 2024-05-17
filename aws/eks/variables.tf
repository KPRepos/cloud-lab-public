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


variable "deploy_pod_identity" {
  type        = string
  description = "pod_identity_deploy ?"
}


variable "pod_identity_role_name" {
  type        = string
  description = "The name of your pod_identity role"
}

variable "authentication_mode" {
  description = "The authentication mode for the cluster. Valid values are `CONFIG_MAP`, `API` or `API_AND_CONFIG_MAP`"
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "access_entries" {
  description = "Map of access entries to add to the cluster"
  type        = any
  default     = {}
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Indicates whether or not to add the cluster creator (the identity used by Terraform) as an administrator via access entry"
  type        = bool
  default     = false
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



variable "enable_nat_gateway" {
  type    = string
  default = false
}


variable "enable_karpenter" {
  type        = string
  description = "version"
  default     = "false"
}

variable "cluster_version" {
  type = string
}


#############################################################################
# Cluster IAM Role
################################################################################

variable "create_iam_role" {
  description = "Determines whether a an IAM role is created or to use an existing IAM role"
  type        = bool
  default     = true
}

variable "iam_role_arn" {
  description = "Existing IAM role ARN for the cluster. Required if `create_iam_role` is set to `false`"
  type        = string
  default     = null
}

variable "iam_role_name" {
  description = "Name to use on IAM role created"
  type        = string
  default     = null
}

variable "iam_role_use_name_prefix" {
  description = "Determines whether the IAM role name (`iam_role_name`) is used as a prefix"
  type        = bool
  default     = true
}

variable "iam_role_path" {
  description = "Cluster IAM role path"
  type        = string
  default     = null
}

variable "iam_role_description" {
  description = "Description of the role"
  type        = string
  default     = null
}

variable "iam_role_permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the IAM role"
  type        = string
  default     = null
}

variable "iam_role_additional_policies" {
  description = "Additional policies to be added to the IAM role"
  type        = map(string)
  default     = {}
}

variable "iam_role_tags" {
  description = "A map of additional tags to add to the IAM role created"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "create" {
  description = "Controls if resources should be created (affects nearly all resources)"
  type        = bool
  default     = true
}

variable "policy_arn" {
  description = "EKS policy arn"
  type        = string
}
