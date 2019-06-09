variable "project" {
  type = string
  description = "Google Cloud project name"
}

variable "credential_file" {
  type = string
  description = "Google Cloud credential file json"
}

# Backend for storing terraform state, must be present on terraform init
terraform {
  backend "gcs" {
    bucket = "gke-from-scratch-terraform-state"
    prefix = "cybertruck"
    credentials = "~/cybertruck-admin.json"
  }
}

provider "google" {
  credentials = file(var.credential_file)
  project     = var.project
}
