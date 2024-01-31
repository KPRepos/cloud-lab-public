output "vpc_name" {
  description = "The name of the VPC."
  value       = google_compute_network.vpc_network.name
}

output "vpc_self_link" {
  description = "The self link of the VPC."
  value       = google_compute_network.vpc_network.self_link
}

output "public_subnet_1_name" {
  description = "The name of public_subnet_1."
  value       = google_compute_subnetwork.public_subnet_1.name
}

output "public_subnet_1_ip_range" {
  description = "The IP CIDR range of public_subnet_1."
  value       = google_compute_subnetwork.public_subnet_1.ip_cidr_range
}

output "public_subnet_1_self_link" {
  description = "The self link of public_subnet_1."
  value       = google_compute_subnetwork.public_subnet_1.self_link
}

output "private_subnet_1_name" {
  description = "The name of private_subnet_1."
  value       = google_compute_subnetwork.private_subnet_1.name
}

output "private_subnet_1_ip_range" {
  description = "The IP CIDR range of private_subnet_1."
  value       = google_compute_subnetwork.private_subnet_1.ip_cidr_range
}

output "private_subnet_1_self_link" {
  description = "The self link of private_subnet_1."
  value       = google_compute_subnetwork.private_subnet_1.self_link
}

# k8s-pods

output "private_subnetwork_secondary_cidr_block_1" {
  value = google_compute_subnetwork.private_subnet_1.secondary_ip_range[0].ip_cidr_range
}

output "private_subnetwork_secondary_range_name_1" {
  value = google_compute_subnetwork.private_subnet_1.secondary_ip_range[0].range_name
}

# k8s-services
output "private_subnetwork_secondary_cidr_block_2" {
  value = google_compute_subnetwork.private_subnet_1.secondary_ip_range[1].ip_cidr_range
}

output "private_subnetwork_secondary_range_name_2" {
  value = google_compute_subnetwork.private_subnet_1.secondary_ip_range[1].range_name
}
