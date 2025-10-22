# Cloud Storage Configuration for Frontend Hosting

# Create Cloud Storage bucket for frontend hosting
resource "google_storage_bucket" "frontend" {
  name          = "${var.project_id}-${var.frontend_bucket_name}-${var.environment}"
  location      = "US"
  force_destroy = true # Set to false for production
  
  labels = var.labels

  # Website configuration
  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html" # SPA routing
  }

  # CORS configuration for frontend
  cors {
    origin          = ["*"] # Restrict in production
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  # Versioning (optional for production)
  versioning {
    enabled = var.environment == "prod"
  }

  # Lifecycle rule to clean up old versions
  dynamic "lifecycle_rule" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      condition {
        age                   = 30
        with_state           = "ARCHIVED"
        num_newer_versions   = 5
      }
      action {
        type = "Delete"
      }
    }
  }

  # Public access prevention (we'll set specific IAM instead)
  public_access_prevention = "inherited"
}

# Make the bucket publicly readable
resource "google_storage_bucket_iam_member" "frontend_public_read" {
  bucket = google_storage_bucket.frontend.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Create Cloud Storage bucket for storing application assets/uploads (if needed)
resource "google_storage_bucket" "assets" {
  name          = "${var.project_id}-${var.app_name}-assets-${var.environment}"
  location      = var.region
  force_destroy = true # Set to false for production
  
  labels = var.labels

  # CORS configuration for asset uploads
  cors {
    origin          = var.environment == "prod" ? ["https://${var.domain_name}"] : ["*"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  # Versioning for assets
  versioning {
    enabled = true
  }

  # Lifecycle management
  lifecycle_rule {
    condition {
      age = 365 # Delete files older than 1 year
    }
    action {
      type = "Delete"
    }
  }

  # Lifecycle rule for multipart uploads cleanup
  lifecycle_rule {
    condition {
      age                        = 1
      matches_storage_class      = []
      num_newer_versions        = 0
      with_state               = "LIVE"
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}

# IAM for backend service to access assets bucket
resource "google_storage_bucket_iam_member" "backend_assets_admin" {
  bucket = google_storage_bucket.assets.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.cloudrun_sa.email}"
}

# Create service account for frontend CI/CD
resource "google_service_account" "frontend_deployer" {
  account_id   = "${var.app_name}-frontend-deploy-${var.environment}"
  display_name = "Frontend Deployment Service Account"
  description  = "Service account for deploying frontend to Cloud Storage"
}

# Grant permissions to upload frontend files
resource "google_storage_bucket_iam_member" "frontend_deployer_admin" {
  bucket = google_storage_bucket.frontend.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.frontend_deployer.email}"
}