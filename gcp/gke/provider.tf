terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.4.0"
    }
  }

  required_version = ">= 0.14"
}

provider "google" {
  project = "kprepos-lab"
}
