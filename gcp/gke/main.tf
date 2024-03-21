
module "vpc" {
  source           = "../modules/vpc"
  project_id       = var.project_id
  vpc_name         = var.vpc_name
  region           = var.region
  enable_cloud_nat = var.enable_cloud_nat
  env_name         = var.env_name

}


module "gke" {
  source                            = "../modules/gke"
  env_name                          = var.env_name
  project_id                        = var.project_id
  project                           = var.project
  region                            = var.region
  location                          = var.location
  zone1                             = var.zone1
  zone2                             = var.zone2
  network                           = module.vpc.vpc_self_link
  subnetwork                        = module.vpc.private_subnet_1_self_link
  google_compute_network            = module.vpc.vpc_self_link
  google_compute_subnetwork         = module.vpc.private_subnet_1_self_link
  disable_public_endpoint           = var.disable_public_endpoint
  enable_private_nodes              = var.enable_private_nodes
  master_ipv4_cidr_block            = var.master_ipv4_cidr_block
  cluster_secondary_range_name      = var.cluster_secondary_range_name
  services_secondary_range_name     = var.services_secondary_range_name
  name                              = var.name
  enable_dataplane_v2               = var.enable_dataplane_v2
  enable_network_policy             = var.enable_network_policy # have to be false when dataplane-v2 enabled
  version_nodepool                  = var.version_nodepool
  version_cluster                   = var.version_cluster
  primary_node_pool_min_node_count  = var.primary_node_pool_min_node_count
  primary_node_pool_max_node_count  = var.primary_node_pool_max_node_count
  primary_node_pool_machine_type    = var.primary_node_pool_machine_type
  preemptible_spot                  = var.preemptible_spot
  master_authorized_networks_config = var.master_authorized_networks_config

}

