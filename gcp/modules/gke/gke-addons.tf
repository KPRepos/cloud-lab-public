resource "google_secret_manager_secret" "secret-basic" {
  depends_on = [google_project_service.secrets_manager]
  secret_id  = "${var.env_name}-secret"

  labels = {
    label = "gke-secrets"
  }

  replication {
    user_managed {
      #   replicas {
      #     location = "us-central1"
      #   }
      replicas {
        location = var.region
      }
    }
  }
}
