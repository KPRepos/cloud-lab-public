resource "google_service_account" "gke_node" {
  account_id   = "${var.env_name}-gke-node-sa"
  display_name = "GKE Node Service Account"
}

resource "google_project_iam_member" "gke_node_log_writer" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_node.email}"
}

resource "google_project_iam_member" "gke_node_metric_writer" {
  project = var.project
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_node.email}"
}

resource "google_project_iam_member" "gke_node_storage_viewer" {
  project = var.project
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.gke_node.email}"
}

# resource "google_project_iam_member" "gke_node_network_viewer" {
#   project = "your-gcp-project-id"
#   role    = "roles/compute.networkViewer"
#   member  = "serviceAccount:${google_service_account.gke_node.email}"
# }

