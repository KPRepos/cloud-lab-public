# terraform {
#   backend "s3" {
#     bucket = "tf-lab-state-bucket"
#     key    = "lab-latest.state"
#     region = "us-west-2"
#   }
# }



provider "aws" {
  region = local.region
}

terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    # Other providers...
  }
  # Other Terraform settings...
}
