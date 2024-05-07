
# GKE cluster
data "google_container_engine_versions" "gke_version" {
  depends_on     = [google_project_service.kubernetes_engine]
  location       = var.region
  version_prefix = "1.27."
}



locals {
  combined_cidr_blocks = concat(
    [{ cidr_block = "${jsondecode(data.http.my_public_ip.body).ip}/32", display_name = "Local Public IP" }],
    flatten([for config in var.master_authorized_networks_config : config.cidr_blocks])
  )
  # public_ip = jsondecode(data.http.my_public_ip.body).ip
}

# Get My Public IP
data "http" "my_public_ip" {
  url = "https://ipinfo.io/json"
  request_headers = {
    Accept = "application/json"
  }

}


resource "google_container_cluster" "primary" {
  depends_on = [google_project_service.kubernetes_engine]
  provider   = google-beta

  name        = var.name
  description = var.description

  project           = var.project
  location          = var.location
  node_locations    = [var.zone1]
  network           = var.network
  subnetwork        = var.subnetwork
  datapath_provider = var.enable_dataplane_v2 ? "ADVANCED_DATAPATH" : "DATAPATH_PROVIDER_UNSPECIFIED"
  # enable_autopilot   = false
  logging_service    = var.logging_service
  monitoring_service = var.monitoring_service
  # min_master_version = local.kubernetes_version
  min_master_version  = var.version_cluster
  deletion_protection = false

  # Whether to enable legacy Attribute-Based Access Control (ABAC). RBAC has significant security advantages over ABAC.
  enable_legacy_abac = var.enable_legacy_abac

  # The API requires a node pool or an initial count to be defined; that initial count creates the
  # "default node pool" with that # of nodes.
  # So, we need to set an initial_node_count of 1. This will make a default node
  # pool with server-defined defaults that Terraform will immediately delete as
  # part of Create. This leaves us in our desired state- with a cluster master
  # with no node pools.
  remove_default_node_pool = true

  initial_node_count = 1

  ## For istio and Gateway 
  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }
  # If we have an alternative default service account to use, set on the node_config so that the default node pool can
  # be created successfully.
  dynamic "node_config" {
    # Ideally we can do `for_each = var.alternative_default_service_account != null ? [object] : []`, but due to a
    # terraform bug, this doesn't work. See https://github.com/hashicorp/terraform/issues/21465. So we simulate it using
    # a for expression.
    for_each = [
      for x in [var.alternative_default_service_account] : x if var.alternative_default_service_account != null
    ]

    content {
      service_account = node_config.value
    }
  }

  # ip_allocation_policy.use_ip_aliases defaults to true, since we define the block `ip_allocation_policy`
  ip_allocation_policy {
    // Choose the range, but let GCP pick the IPs within the range
    cluster_secondary_range_name  = var.cluster_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  # We can optionally control access to the cluster
  # See https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters
  private_cluster_config {
    enable_private_endpoint = var.disable_public_endpoint
    enable_private_nodes    = var.enable_private_nodes
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  addons_config {
    http_load_balancing {
      disabled = !var.http_load_balancing
    }

    horizontal_pod_autoscaling {
      disabled = !var.horizontal_pod_autoscaling
    }

    network_policy_config {
      disabled = !var.enable_network_policy
    }
  }

  network_policy {
    enabled = var.enable_network_policy

    # Tigera (Calico Felix) is the only provider
    provider = var.enable_network_policy ? "CALICO" : "PROVIDER_UNSPECIFIED"
  }

  vertical_pod_autoscaling {
    enabled = var.enable_vertical_pod_autoscaling
  }

  # master_auth {
  #   username = var.basic_auth_username
  #   password = var.basic_auth_password
  # }


  dynamic "master_authorized_networks_config" {
    for_each = [1] # A dummy list to create the block exactly once

    content {
      dynamic "cidr_blocks" {
        for_each = local.combined_cidr_blocks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }


  maintenance_policy {
    daily_maintenance_window {
      start_time = var.maintenance_start_time
    }
  }

  lifecycle {
    ignore_changes = [
      # Since we provide `remove_default_node_pool = true`, the `node_config` is only relevant for a valid construction of
      # the GKE cluster in the initial creation. As such, any changes to the `node_config` should be ignored.
      node_config,
    ]
  }

  # If var.gsuite_domain_name is non-empty, initialize the cluster with a G Suite security group
  dynamic "authenticator_groups_config" {
    for_each = [
      for x in [var.gsuite_domain_name] : x if var.gsuite_domain_name != null
    ]

    content {
      security_group = "gke-security-groups@${authenticator_groups_config.value}"
    }
  }

  # If var.secrets_encryption_kms_key is non-empty, create ´database_encryption´ -block to encrypt secrets at rest in etcd
  dynamic "database_encryption" {
    for_each = [
      for x in [var.secrets_encryption_kms_key] : x if var.secrets_encryption_kms_key != null
    ]

    content {
      state    = "ENCRYPTED"
      key_name = database_encryption.value
    }
  }

  # dynamic "workload_identity_config" {
  #   for_each = local.workload_identity_config

  #   content {
  #     identity_namespace = workload_identity_config.value.identity_namespace
  #   }
  # }

  resource_labels = var.resource_labels
}

# ---------------------------------------------------------------------------------------------------------------------
# Prepare locals to keep the code cleaner
# ---------------------------------------------------------------------------------------------------------------------

locals {
  latest_version     = data.google_container_engine_versions.location.latest_master_version
  kubernetes_version = var.kubernetes_version != "latest" ? var.kubernetes_version : local.latest_version
  network_project    = var.network_project != "" ? var.network_project : var.project
}

# ---------------------------------------------------------------------------------------------------------------------
# Pull in data
# ---------------------------------------------------------------------------------------------------------------------

// Get available master versions in our location to determine the latest version
data "google_container_engine_versions" "location" {
  depends_on = [google_project_service.kubernetes_engine]
  location   = var.location
  project    = var.project
}






# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes_zone1" {
  depends_on = [google_project_service.kubernetes_engine]
  # count    = 0
  name     = google_container_cluster.primary.name
  location = var.region
  # # zone    = "us-west3-a"
  cluster = google_container_cluster.primary.name

  # version    = data.google_container_engine_versions.gke_version.release_channel_latest_version["STABLE"]
  version    = var.version_nodepool
  node_count = var.gke_num_nodes

  autoscaling {
    min_node_count = var.primary_node_pool_min_node_count
    max_node_count = var.primary_node_pool_max_node_count
  }

  node_config {
    service_account = google_service_account.gke_node.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      ""https://www.googleapis.com/auth/devstorage.read_only"
    ]

    labels = {
      env = var.project_id
    }

    disk_size_gb    = 50
    local_ssd_count = 0
    disk_type       = "pd-standard" #to get around gcp limits with ssd 
    preemptible     = var.preemptible_spot
    machine_type    = var.primary_node_pool_machine_type
    tags            = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}






# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes_zone2" {
  depends_on = [google_project_service.kubernetes_engine]
  count      = 0
  name       = "kp-lab-k8-nodepool-2"
  location   = var.region
  # # zone    = "us-west3-a"
  cluster = google_container_cluster.primary.name

  # version    = data.google_container_engine_versions.gke_version.release_channel_latest_version["STABLE"]
  version    = var.version_nodepool
  node_count = var.gke_num_nodes

  autoscaling {
    min_node_count = 0
    max_node_count = 1
  }
  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.project_id
    }

    disk_size_gb    = 50
    local_ssd_count = 0
    disk_type       = "pd-standard" #to get around gcp limits with ssd 
    # preemptible  = true
    machine_type = "n1-standard-1"
    tags         = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}
