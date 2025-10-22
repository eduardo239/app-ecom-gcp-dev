# Terraform Outputs

# Network outputs
output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.vpc_network.name
}

output "vpc_network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.vpc_network.id
}

# Database outputs
output "database_instance_name" {
  description = "Name of the Cloud SQL database instance"
  value       = google_sql_database_instance.main.name
}

output "database_connection_name" {
  description = "Connection name for the Cloud SQL instance"
  value       = google_sql_database_instance.main.connection_name
}

output "database_private_ip" {
  description = "Private IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.main.private_ip_address
}

output "database_name" {
  description = "Name of the application database"
  value       = google_sql_database.database.name
}

output "database_user" {
  description = "Database user name"
  value       = google_sql_user.user.name
  sensitive   = true
}

# Backend service outputs
output "backend_service_url" {
  description = "URL of the Cloud Run backend service"
  value       = google_cloud_run_v2_service.backend.uri
}

output "backend_service_name" {
  description = "Name of the Cloud Run backend service"
  value       = google_cloud_run_v2_service.backend.name
}

output "backend_service_account_email" {
  description = "Email of the Cloud Run service account"
  value       = google_service_account.cloudrun_sa.email
}

# Frontend outputs
output "frontend_bucket_name" {
  description = "Name of the frontend Cloud Storage bucket"
  value       = google_storage_bucket.frontend.name
}

output "frontend_bucket_url" {
  description = "URL of the frontend Cloud Storage bucket"
  value       = google_storage_bucket.frontend.url
}

output "assets_bucket_name" {
  description = "Name of the assets Cloud Storage bucket"
  value       = google_storage_bucket.assets.name
}

# Load balancer outputs
output "load_balancer_ip" {
  description = "Global IP address of the load balancer"
  value       = google_compute_global_address.lb_ip.address
}

output "load_balancer_ip_name" {
  description = "Name of the global IP address"
  value       = google_compute_global_address.lb_ip.name
}

# Artifact Registry outputs
output "artifact_registry_repository" {
  description = "Name of the Artifact Registry repository"
  value       = google_artifact_registry_repository.container_repo.name
}

output "artifact_registry_location" {
  description = "Location of the Artifact Registry repository"
  value       = google_artifact_registry_repository.container_repo.location
}

# Secret Manager outputs
output "db_password_secret_name" {
  description = "Name of the database password secret in Secret Manager"
  value       = google_secret_manager_secret.db_password.secret_id
}

# Service account outputs
output "cloudbuild_service_account_email" {
  description = "Email of the Cloud Build service account"
  value       = google_service_account.cloudbuild_sa.email
}

output "frontend_deployer_service_account_email" {
  description = "Email of the frontend deployment service account"
  value       = google_service_account.frontend_deployer.email
}

# Domain and SSL outputs
output "ssl_certificate_name" {
  description = "Name of the managed SSL certificate"
  value       = var.domain_name != "" ? google_compute_managed_ssl_certificate.ssl_cert[0].name : null
}

# VPC Connector outputs
output "vpc_connector_name" {
  description = "Name of the VPC Access connector"
  value       = google_vpc_access_connector.connector.name
}

# Environment information
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "region" {
  description = "GCP Region"
  value       = var.region
}

# Application URLs (computed)
output "application_urls" {
  description = "Application URLs for different components"
  value = {
    backend_api        = google_cloud_run_v2_service.backend.uri
    frontend_storage   = "https://storage.googleapis.com/${google_storage_bucket.frontend.name}/index.html"
    load_balancer_ip   = "http://${google_compute_global_address.lb_ip.address}"
    custom_domain      = var.domain_name != "" ? "https://${var.domain_name}" : null
  }
}

# Deployment information
output "deployment_info" {
  description = "Information needed for deployment"
  value = {
    project_id                    = var.project_id
    region                       = var.region
    backend_service_name         = google_cloud_run_v2_service.backend.name
    frontend_bucket_name         = google_storage_bucket.frontend.name
    artifact_registry_repo       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.container_repo.name}"
    database_connection_name     = google_sql_database_instance.main.connection_name
    cloudbuild_sa_email         = google_service_account.cloudbuild_sa.email
    frontend_deployer_sa_email  = google_service_account.frontend_deployer.email
  }
}