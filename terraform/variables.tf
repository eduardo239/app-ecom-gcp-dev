# Variables for GCP E-commerce Infrastructure

variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
  validation {
    condition     = length(var.project_id) > 0
    error_message = "Project ID must not be empty."
  }
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for resources that require it"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "app_name" {
  description = "Application name used for resource naming"
  type        = string
  default     = "ecom-app"
}

# Database Configuration
variable "database_tier" {
  description = "Cloud SQL database tier"
  type        = string
  default     = "db-f1-micro"
}

variable "database_version" {
  description = "PostgreSQL version for Cloud SQL"
  type        = string
  default     = "POSTGRES_14"
}

variable "database_name" {
  description = "Name of the application database"
  type        = string
  default     = "ecommerce"
}

variable "database_user" {
  description = "Database user name"
  type        = string
  default     = "appuser"
}

# Cloud Run Configuration
variable "backend_image" {
  description = "Container image for the backend service"
  type        = string
  default     = "gcr.io/cloudrun/hello" # Placeholder, will be replaced during deployment
}

variable "backend_service_name" {
  description = "Name of the Cloud Run backend service"
  type        = string
  default     = "ecom-backend"
}

variable "max_instances" {
  description = "Maximum number of Cloud Run instances"
  type        = number
  default     = 10
}

variable "cpu_limit" {
  description = "CPU limit for Cloud Run instances"
  type        = string
  default     = "1000m"
}

variable "memory_limit" {
  description = "Memory limit for Cloud Run instances"
  type        = string
  default     = "512Mi"
}

# Frontend Configuration
variable "frontend_bucket_name" {
  description = "Name of the Cloud Storage bucket for frontend (will be prefixed with project ID)"
  type        = string
  default     = "frontend"
}

# Domain Configuration
variable "domain_name" {
  description = "Custom domain name (optional)"
  type        = string
  default     = ""
}

# Tags and Labels
variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default = {
    application = "ecommerce"
    managed-by  = "terraform"
  }
}