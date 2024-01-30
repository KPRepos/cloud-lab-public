# terraform {
#   backend "s3" {
#     bucket = "tf-lab-state-bucket"
#     key    = "lab-latest.state"
#     region = "us-west-2"
#   }
# }

# Ignore tags added to get around alb tagging post vpc and eks  deployment
provider "aws" {
  region = local.region
  ignore_tags {
    key_prefixes = ["kubernetes.io/role/*"]
  }
}
