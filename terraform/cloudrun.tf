# Cloud Run Service Configuration

# Create service account for Cloud Run
resource "google_service_account" "cloudrun_sa" {
  account_id   = "${var.app_name}-cloudrun-${var.environment}"
  display_name = "Cloud Run Service Account for ${var.app_name}"
  description  = "Service account for Cloud Run backend service"
}

# Grant necessary permissions to the service account
resource "google_project_iam_member" "cloudrun_sa_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloudrun_sa.email}"
}

resource "google_project_iam_member" "cloudrun_sa_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloudrun_sa.email}"
}

# Create VPC Connector for Cloud Run to access private VPC
resource "google_vpc_access_connector" "connector" {
  name          = "${var.app_name}-vpc-connector-${var.environment}"
  region        = var.region
  network       = google_compute_network.vpc_network.name
  ip_cidr_range = "10.8.0.0/28"
  
  depends_on = [
    google_compute_network.vpc_network,
    google_project_service.required_apis
  ]
}

# Cloud Run Service
resource "google_cloud_run_v2_service" "backend" {
  name     = var.backend_service_name
  location = var.region
  
  labels = var.labels

  template {
    # Service account
    service_account = google_service_account.cloudrun_sa.email
    
    # VPC access
    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress    = "PRIVATE_RANGES_ONLY"
    }
    
    # Scaling configuration
    scaling {
      min_instance_count = var.environment == "prod" ? 1 : 0
      max_instance_count = var.max_instances
    }

    containers {
      image = var.backend_image
      
      # Resource limits
      resources {
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
        cpu_idle = true
        startup_cpu_boost = true
      }

      # Environment variables
      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }
      
      env {
        name  = "DATABASE_URL"
        value = "postgresql://${var.database_user}:${random_password.db_password.result}@${google_sql_database_instance.main.private_ip_address}:5432/${var.database_name}"
      }
      
      env {
        name  = "FLASK_ENV"
        value = var.environment == "prod" ? "production" : "development"
      }
      
      env {
        name  = "PORT"
        value = "8080"
      }

      # Health check
      startup_probe {
        http_get {
          path = "/health"
          port = 8080
        }
        initial_delay_seconds = 10
        timeout_seconds       = 5
        period_seconds       = 10
        failure_threshold    = 3
      }

      liveness_probe {
        http_get {
          path = "/health"
          port = 8080
        }
        initial_delay_seconds = 30
        timeout_seconds       = 5
        period_seconds       = 30
        failure_threshold    = 3
      }

      # Container port
      ports {
        container_port = 8080
      }
    }
  }

  # Traffic configuration
  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }

  depends_on = [
    google_vpc_access_connector.connector,
    google_sql_database_instance.main,
    google_service_account.cloudrun_sa,
    google_project_service.required_apis
  ]
}

# Allow unauthenticated access to Cloud Run service
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_v2_service.backend.name
  location = google_cloud_run_v2_service.backend.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Custom domain mapping (optional)
resource "google_cloud_run_domain_mapping" "backend_domain" {
  count = var.domain_name != "" ? 1 : 0
  
  location = var.region
  name     = "api.${var.domain_name}"

  metadata {
    namespace = var.project_id
  }

  spec {
    route_name = google_cloud_run_v2_service.backend.name
  }
}