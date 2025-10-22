# IAM and Security Configuration

# Create service account for Cloud Build (CI/CD)
resource "google_service_account" "cloudbuild_sa" {
  account_id   = "${var.app_name}-cloudbuild-${var.environment}"
  display_name = "Cloud Build Service Account"
  description  = "Service account for Cloud Build CI/CD pipeline"
}

# Grant Cloud Build service account necessary permissions
resource "google_project_iam_member" "cloudbuild_sa_roles" {
  for_each = toset([
    "roles/cloudbuild.builds.builder",
    "roles/run.admin",
    "roles/storage.admin",
    "roles/artifactregistry.writer",
    "roles/iam.serviceAccountUser",
    "roles/secretmanager.secretAccessor"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloudbuild_sa.email}"
}

# Create Artifact Registry for container images
resource "google_artifact_registry_repository" "container_repo" {
  location      = var.region
  repository_id = "${var.app_name}-repo-${var.environment}"
  description   = "Container repository for ${var.app_name}"
  format        = "DOCKER"
  
  labels = var.labels
  
  depends_on = [google_project_service.required_apis]
}

# Grant Cloud Build access to Artifact Registry
resource "google_artifact_registry_repository_iam_member" "cloudbuild_repo_access" {
  project    = var.project_id
  location   = google_artifact_registry_repository.container_repo.location
  repository = google_artifact_registry_repository.container_repo.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.cloudbuild_sa.email}"
}

# Create custom IAM role for minimal backend permissions
resource "google_project_iam_custom_role" "backend_minimal" {
  role_id     = "${var.app_name}_backend_minimal_${var.environment}"
  title       = "Backend Service Minimal Role"
  description = "Minimal permissions for backend service"
  
  permissions = [
    "cloudsql.instances.connect",
    "secretmanager.versions.access",
    "storage.objects.get",
    "storage.objects.create",
    "storage.objects.delete"
  ]
}

# Assign custom role to Cloud Run service account
resource "google_project_iam_member" "backend_minimal_role" {
  project = var.project_id
  role    = google_project_iam_custom_role.backend_minimal.name
  member  = "serviceAccount:${google_service_account.cloudrun_sa.email}"
}

# Create service account key for local development (optional)
resource "google_service_account_key" "dev_key" {
  count              = var.environment == "dev" ? 1 : 0
  service_account_id = google_service_account.cloudrun_sa.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

# Store service account key in Secret Manager
resource "google_secret_manager_secret" "dev_service_account_key" {
  count     = var.environment == "dev" ? 1 : 0
  secret_id = "${var.app_name}-dev-sa-key-${var.environment}"
  
  labels = var.labels
  
  replication {
    auto {}
  }
  
  depends_on = [google_project_service.required_apis]
}

resource "google_secret_manager_secret_version" "dev_service_account_key" {
  count       = var.environment == "dev" ? 1 : 0
  secret      = google_secret_manager_secret.dev_service_account_key[0].id
  secret_data = base64decode(google_service_account_key.dev_key[0].private_key)
}

# Security: Enable audit logging
resource "google_project_iam_audit_config" "audit_logs" {
  project = var.project_id
  service = "allServices"
  
  audit_log_config {
    log_type = "ADMIN_READ"
  }
  
  audit_log_config {
    log_type = "DATA_READ"
  }
  
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

# Organization policy: Restrict public IP access (if using organization)
# Uncomment if you have organization-level access
# resource "google_organization_policy" "restrict_public_ip" {
#   org_id     = "your-org-id"
#   constraint = "compute.vmExternalIpAccess"
#   
#   list_policy {
#     deny {
#       all = true
#     }
#   }
# }