provider "google" {
  version     = "~> 3.3"
  credentials = file(var.GCP_AUTH_JSON)
  project     = var.GCP_PROJECT
  region      = var.GCP_REGION
}

provider "google-beta" {
  credentials = file(var.GCP_AUTH_JSON)
  project     = var.GCP_PROJECT
  region      = var.GCP_REGION
}

# Create networking
resource "google_compute_network" "private_network" {
  provider = google-beta
  name = "dtrace-network"
}
resource "google_compute_global_address" "dtrace_address" {
  provider = google-beta
  name          = "dtrace-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.private_network.self_link
}
resource "google_service_networking_connection" "dtrace_net" {
  provider = google-beta
  network = google_compute_network.private_network.self_link
  service = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [
    google_compute_global_address.dtrace_address.name,
  ]
}

# Create CloudSQL database
resource "google_sql_database" "dtrace-master" {
  name     = "dtrace-master-db"
  instance = google_sql_database_instance.cloudsql-db-master.name
}
resource "google_sql_database_instance" "cloudsql-db-master" {
  name             = var.database_name
  database_version = var.database_version
  region           = var.GCP_REGION

  depends_on = [google_service_networking_connection.dtrace_net]

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = true
      require_ssl = true
      private_network = google_compute_network.private_network.self_link
      authorized_networks {
        name = "master_authorized_network"
        value = var.authorized_network
      }
    }
  }
}

# Create root user
resource "google_sql_user" "users" {
  name     = var.gcp_sql_root_user_name
  instance = google_sql_database_instance.cloudsql-db-master.name
  password = var.gcp_sql_root_user_pw
}

# Create GKE cluster
data "google_container_engine_versions" "cengine" {
  location       = var.GCP_ZONE
  version_prefix = "1.16."
}

resource "google_container_cluster" "dtrack_prod_cluster" {
  name                     = var.k8s_cluster_name
  provider                 = google-beta
  description              = "Dependency track cluster"
  location                 = var.GCP_ZONE
  node_version             = data.google_container_engine_versions.cengine.latest_node_version
  min_master_version       = data.google_container_engine_versions.cengine.latest_node_version
  initial_node_count       = var.initial_node_count
  remove_default_node_pool = true
  # Release channel RAPID or REGULAR
  release_channel {
    channel = "RAPID"
  }
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }
  # This uses project calico. This is disabled in favour of istio
  network_policy {
    enabled = false
  }

  master_authorized_networks_config {

  }
  subnetwork = "projects/${var.GCP_PROJECT}/regions/${var.GCP_REGION}/subnetworks/default"

  # Enable shielded GKE nodes
  enable_shielded_nodes = true

  # Enable binary authorization
  enable_binary_authorization = true

  addons_config {
    horizontal_pod_autoscaling {
      disabled = true
    }
    http_load_balancing {
      disabled = true
    }
  }
}

resource "google_container_node_pool" "dtrack_node_pool" {
  name       = "dtrack-node-pool"
  location   = var.GCP_ZONE
  cluster    = google_container_cluster.dtrack_prod_cluster.name
  node_count = var.initial_node_count
  autoscaling {
    min_node_count = var.initial_node_count
    max_node_count = var.max_node_count
  }
  node_config {
    image_type   = "COS"
    machine_type = var.node_machine_type
    disk_size_gb = var.node_disk_size
    disk_type    = "pd-standard"
    preemptible  = true
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append"
    ]
    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = {
      purpose = "dtrack"
    }
    tags = ["java", "owasp", "appthreat"]
  }

  timeouts {
    create = "30m"
    update = "40m"
  }

  management {
    auto_repair  = false
    auto_upgrade = false
  }
}
