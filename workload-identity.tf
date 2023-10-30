variable "pool_id" {
  type        = string
  description = "The Workload Identity Pool ID. Changing this forces a new Workload Identity Pool to be created."
}

variable "pool_provider_id" {
  type        = string
  description = "The Workload Identity Pool Provider ID. Changing this forces a new Workload Identity Pool Provider to be created."
}

resource "google_iam_workload_identity_pool" "oidc_pool" {
  workload_identity_pool_id = var.pool_id
}

resource "google_iam_workload_identity_pool_provider" "oidc_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.oidc_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.pool_provider_id
  attribute_condition                = "\"${var.github_org}\" == assertion.repository_owner" # requires the JWT property to match the provided github org name
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.owner"      = "assertion.repository_owner"
  }
  oidc {
    allowed_audiences = [
      "https://iam.googleapis.com/projects/${var.project_id_number}/locations/global/workloadIdentityPools/${var.pool_id}/providers/${var.pool_provider_id}",
      "https://github.com/${var.github_org}"
    ]
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}
