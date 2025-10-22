# Cloud SQL Database Configuration

# Create a private VPC network for secure database access
resource "google_compute_network" "vpc_network" {
  name                    = "${var.app_name}-vpc-${var.environment}"
  auto_create_subnetworks = false
}

# Create subnet for the VPC
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.app_name}-subnet-${var.environment}"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.vpc_network.self_link
  region        = var.region
}

# Reserve IP range for private services (Cloud SQL)
resource "google_compute_global_address" "private_ip_range" {
  name          = "${var.app_name}-private-ip-${var.environment}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}

# Create private connection for Cloud SQL
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
  
  depends_on = [google_project_service.required_apis]
}

# Cloud SQL Database Instance
resource "google_sql_database_instance" "main" {
  name             = "${var.app_name}-db-${var.environment}"
  database_version = var.database_version
  region           = var.region
  
  deletion_protection = false # Set to true for production

  settings {
    tier                        = var.database_tier
    deletion_protection_enabled = false # Set to true for production
    
    # High availability for production
    availability_type = var.environment == "prod" ? "REGIONAL" : "ZONAL"
    
    # Backup configuration
    backup_configuration {
      enabled                        = true
      start_time                    = "03:00"
      point_in_time_recovery_enabled = var.environment == "prod"
      
      backup_retention_settings {
        retained_backups = var.environment == "prod" ? 30 : 7
        retention_unit   = "COUNT"
      }
    }

    # Database flags for performance
    database_flags {
      name  = "max_connections"
      value = "100"
    }

    # Disk configuration
    disk_type       = "PD_SSD"
    disk_size       = var.environment == "prod" ? 100 : 20
    disk_autoresize = true

    # IP configuration for private networking
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                              = google_compute_network.vpc_network.id
      enable_private_path_for_google_cloud_services = true
      
      # Authorized networks (if you need public access for development)
      dynamic "authorized_networks" {
        for_each = var.environment == "dev" ? [1] : []
        content {
          name  = "allow-all"
          value = "0.0.0.0/0"
        }
      }
    }

    # Maintenance window
    maintenance_window {
      day          = 7
      hour         = 3
      update_track = "stable"
    }
  }

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = false # Set to true for production
  }

  depends_on = [
    google_service_networking_connection.private_vpc_connection,
    google_project_service.required_apis
  ]
}

# Create the application database
resource "google_sql_database" "database" {
  name     = var.database_name
  instance = google_sql_database_instance.main.name
  
  depends_on = [google_sql_database_instance.main]
}

# Create database user
resource "google_sql_user" "user" {
  name     = var.database_user
  instance = google_sql_database_instance.main.name
  password = random_password.db_password.result
  
  depends_on = [google_sql_database_instance.main]
}

# Store database password in Secret Manager
resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.app_name}-db-password-${var.environment}"
  
  labels = var.labels
  
  replication {
    auto {}
  }
  
  depends_on = [google_project_service.required_apis]
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}