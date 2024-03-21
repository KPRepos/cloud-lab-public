project_id                       = "kprepos-lab"
project                          = "kprepos-lab"
region                           = "us-west1"
location                         = "us-west1"
zone1                            = "us-west1-a"
zone2                            = "us-west1-b"
master_ipv4_cidr_block           = "10.0.4.0/28"
cluster_secondary_range_name     = "k8s-pods"
services_secondary_range_name    = "k8s-services"
name                             = "kp-lab-k8-2"
enable_dataplane_v2              = true
enable_network_policy            = false # have to be false when dataplane-v2 enabled
version_nodepool                 = "1.26.8-gke.200"
version_cluster                  = "1.26.8-gke.200"
primary_node_pool_min_node_count = 1
primary_node_pool_max_node_count = 1
primary_node_pool_machine_type   = "n2-standard-2"
preemptible_spot                 = true
enable_private_nodes             = true
#Local Public IP of terminal will automatically added to this, below list is additional 
master_authorized_networks_config = [{
  cidr_blocks = [
    {
      cidr_block   = "4.4.4.4/32"
      display_name = "Public-IP-Whitelist-example"
    },
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "Public-IP-Whitelist"
    }
  ],
}]

vpc_name         = "gke-lab-vpc"
enable_cloud_nat = true # to provide Egress access to GKE nodes, NAt is expensive - Set to false if not required. 
env_name         = "test2"
