terraform {
  backend "gcs" {
    bucket = "tf-state-gcp-gh-actions"
    prefix = "tofu/state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.1.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.1.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
  }
}

provider "google" {
  region  = var.region
  project = var.project_id
}

provider "google-beta" {
  region  = var.region
  project = var.project_id
}