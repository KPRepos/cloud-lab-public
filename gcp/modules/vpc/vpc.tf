resource "google_compute_network" "vpc_network" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  project                 = var.project_id
}

resource "google_compute_subnetwork" "private_subnet_1" {
  name          = "private-subnet-1"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
  secondary_ip_range {
    range_name    = "k8s-pods"
    ip_cidr_range = "172.22.0.0/16"
  }
  secondary_ip_range {
    range_name    = "k8s-services"
    ip_cidr_range = "172.16.2.0/24"
  }
  private_ip_google_access = true
}


resource "google_compute_subnetwork" "public_subnet_1" {
  name          = "public-subnet-1"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}



resource "google_compute_firewall" "public_ingress_from_internet" {
  name    = "public-ingress-from-internet"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "443"] # You can modify ports as needed
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["public-subnet-1"]
}



resource "google_compute_firewall" "allow-ssh" {
  name = "allow-ssh"
  # project = "devops-counsel-demo"
  network = google_compute_network.vpc_network.id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}


resource "google_compute_firewall" "allow-internal" {
  name    = "allow-internal"
  project = var.project_id
  network = google_compute_network.vpc_network.id
  allow {
    protocol = "tcp"
    ports    = ["1-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["1-65535"]
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["172.16.0.0/24", "172.16.1.0/24", "172.16.2.0/24"]
}


resource "google_compute_router" "cloud_router" {
  name    = "cloud-router"
  region  = var.region
  network = google_compute_network.vpc_network.id # Replace with your VPC name
}

resource "google_compute_router_nat" "cloud_nat" {
  count                              = var.enable_cloud_nat ? 1 : 0
  name                               = "cloud-nat"
  router                             = google_compute_router.cloud_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.private_subnet_1.self_link
    source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE"]
  }
}

