variable "cluster_name" {
  type = string
  description = "Cluster name"
}

variable "location" {
  type = string
  description = "Default Google Cloud region or zone"
  default = "europe-north1"
}

variable "cluster_version"{
  type = string
  description = "Kubernetes version"
  default = "1.15.7-gke.23"
}

variable "machine_type" {
  type = string
  description = "Machine type to use for the general-purpose node pool. See https://cloud.google.com/compute/docs/machine-types"
  default = "n1-standard-1"
}

variable "nodes" {
  type = string
  description = "The number of nodes PER ZONE in the general-purpose node pool"
  default = "1"
}

variable "network_policy" {
  type = string
  description = "Boolean, enable or not the network policy (default: true)"
  default = "true"
}

variable "network_policy_provider" {
  type = string
  description = "Provider for network policies (default: CALICO)"
  default = "CALICO"
}

resource "google_container_cluster" "cluster" {
  name     = "${var.project}-${var.cluster_name}"
  location = var.location

  initial_node_count = var.nodes
  node_version = var.cluster_version
  min_master_version = var.cluster_version

  # Setting an empty username and password explicitly disables basic auth
  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = true
    }
  }

  node_config {
    machine_type = var.machine_type

    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Needed for correctly functioning cluster, see 
    # https://www.terraform.io/docs/providers/google/r/container_cluster.html#oauth_scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only"
    ]
  }

  addons_config {
    network_policy_config {
      disabled = "false"
    }
  }

  network_policy {
    enabled = var.network_policy
    provider = var.network_policy_provider
  }

}

# The following outputs allow authentication and connectivity to the GKE Cluster
# by using certificate-based authentication.
output "client_certificate" {
  value = google_container_cluster.cluster.master_auth.0.client_certificate
}

output "client_key" {
  value = google_container_cluster.cluster.master_auth.0.client_key
}

output "cluster_ca_certificate" {
  value = google_container_cluster.cluster.master_auth.0.cluster_ca_certificate
}