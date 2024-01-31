# Enable Kubernetes Engine API
resource "google_project_service" "kubernetes_engine" {
  service = "container.googleapis.com"

  disable_dependent_services = true

  # Optional: wait for the service to be enabled before continuing
  disable_on_destroy = false
  lifecycle {
    ignore_changes = [
      disable_on_destroy, # This ensures Terraform doesn't disable the API on resource destruction.
    ]
  }

}


# Enable Secrets Manager API
resource "google_project_service" "secrets_manager" {
  service = "secretmanager.googleapis.com"

  disable_dependent_services = true

  # Optional: wait for the service to be enabled before continuing
  disable_on_destroy = false
  lifecycle {
    ignore_changes = [
      disable_on_destroy, # This ensures Terraform doesn't disable the API on resource destruction.
    ]
  }

}


# Compute Engine API
resource "google_project_service" "compute_engine" {
  service = "compute.googleapis.com"

  disable_dependent_services = true

  # Optional: wait for the service to be enabled before continuing
  disable_on_destroy = false
  lifecycle {
    ignore_changes = [
      disable_on_destroy, # This ensures Terraform doesn't disable the API on resource destruction.
    ]
  }

}

