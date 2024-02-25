locals {
  # name   = "lab-${replace(basename(path.cwd), "_", "-")}"
  name     = var.env_name
  region   = var.region
  vpc_cidr = var.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

}


locals {
  public_ip = jsondecode(data.http.my_public_ip.body).ip
}

# Get Availability zones in the Region
data "aws_availability_zones" "AZ" {}


# Get My Public IP
data "http" "my_public_ip" {
  url = "https://ipinfo.io/json"
  request_headers = {
    Accept = "application/json"
  }
}



data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}


# Get the AMI for Ubuntu 22.04
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}
