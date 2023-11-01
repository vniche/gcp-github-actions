variable "cloud_run_account_id" {
  type        = string
  description = "The service account ID. Changing this forces a new service account to be created."
}

resource "google_project_service" "required_services" {
  for_each = toset(["artifactregistry.googleapis.com", "secretmanager.googleapis.com", "iamcredentials.googleapis.com", "run.googleapis.com"])

  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "cloud_run_service_account" {
  account_id = var.cloud_run_account_id
}

resource "google_service_account_iam_binding" "cloud_run_service_account_binding" {
  service_account_id = google_service_account.cloud_run_service_account.name
  role               = "roles/iam.workloadIdentityUser"
  members            = ["principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.oidc_pool.name}/attribute.owner/${var.github_org}"]
  depends_on         = [google_iam_workload_identity_pool.oidc_pool]
}

resource "google_project_iam_member" "service_account_membership" {
  for_each = toset(["roles/artifactregistry.reader", "roles/artifactregistry.writer", "roles/run.admin", "roles/cloudscheduler.admin"])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloud_run_service_account.email}"
}

resource "google_artifact_registry_repository" "image_repository" {
  provider      = google-beta
  repository_id = "cloud-run"
  format        = "DOCKER"

  cleanup_policies {
    id     = "keep-last-10"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }

  depends_on = [google_project_service.required_services]
}

resource "random_uuid" "bucket_uuid" {}

resource "google_storage_bucket" "iac_state_bucket" {
  name     = "cloud-run-${random_uuid.bucket_uuid.result}"
  location = var.region
}

resource "google_storage_bucket_iam_binding" "iac_state_bucket_iam_binding" {
  bucket  = google_storage_bucket.iac_state_bucket.name
  role    = "roles/storage.folderAdmin"
  members = ["serviceAccount:${google_service_account.cloud_run_service_account.email}"]
}
