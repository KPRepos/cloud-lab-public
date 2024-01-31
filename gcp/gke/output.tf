# Output to verify deployment
output "vpc_id" {
  value = module.vpc.vpc_self_link
}

# Output for VPC Name
output "vpc_name" {
  description = "The name of the VPC deployed by the VPC module."
  value       = module.vpc.vpc_name
}

# Output for VPC Self Link
output "vpc_self_link" {
  description = "The self link of the VPC deployed by the VPC module."
  value       = module.vpc.vpc_self_link
}

# Output for Public Subnet 1 Name
output "public_subnet_1_name" {
  description = "The name of public-subnet-1 deployed by the VPC module."
  value       = module.vpc.public_subnet_1_name
}

# Output for Public Subnet 1 IP Range
output "public_subnet_1_ip_range" {
  description = "The IP CIDR range of public-subnet-1 deployed by the VPC module."
  value       = module.vpc.public_subnet_1_ip_range
}

# Output for Public Subnet 1 Self Link
output "public_subnet_1_self_link" {
  description = "The self link of public-subnet-1 deployed by the VPC module."
  value       = module.vpc.public_subnet_1_self_link
}

# Output for Private Subnet 1 Name
output "private_subnet_1_name" {
  description = "The name of private-subnet-1 deployed by the VPC module."
  value       = module.vpc.private_subnet_1_name
}

# Output for Private Subnet 1 IP Range
output "private_subnet_1_ip_range" {
  description = "The IP CIDR range of private-subnet-1 deployed by the VPC module."
  value       = module.vpc.private_subnet_1_ip_range
}

# Output for Private Subnet 1 Self Link
output "private_subnet_1_self_link" {
  description = "The self link of private-subnet-1 deployed by the VPC module."
  value       = module.vpc.private_subnet_1_self_link
}

# Output for Private Subnetwork Secondary CIDR Block for Kubernetes Pods
output "private_subnetwork_secondary_cidr_block_1" {
  description = "The secondary IP CIDR block for Kubernetes pods in private-subnet-1 deployed by the VPC module."
  value       = module.vpc.private_subnetwork_secondary_cidr_block_1
}

# Output for Private Subnetwork Secondary Range Name for Kubernetes Pods
output "private_subnetwork_secondary_range_name_1" {
  description = "The secondary range name for Kubernetes pods in private-subnet-1 deployed by the VPC module."
  value       = module.vpc.private_subnetwork_secondary_range_name_1
}

# Output for Private Subnetwork Secondary CIDR Block for Kubernetes Services
output "private_subnetwork_secondary_cidr_block_2" {
  description = "The secondary IP CIDR block for Kubernetes services in private-subnet-1 deployed by the VPC module."
  value       = module.vpc.private_subnetwork_secondary_cidr_block_2
}

# Output for Private Subnetwork Secondary Range Name for Kubernetes Services
output "private_subnetwork_secondary_range_name_2" {
  description = "The secondary range name for Kubernetes services in private-subnet-1 deployed by the VPC module."
  value       = module.vpc.private_subnetwork_secondary_range_name_2
}


output "kubernetes_cluster_endpoint" {
  value       = module.gke.kubernetes_cluster_endpoint
  description = "GKE Cluster endpoint"
}
