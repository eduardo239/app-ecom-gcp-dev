# Networking, Load Balancer, and CDN Configuration

# Reserve a global static IP address for the load balancer
resource "google_compute_global_address" "lb_ip" {
  name         = "${var.app_name}-lb-ip-${var.environment}"
  address_type = "EXTERNAL"
}

# Create SSL certificate (managed certificate for custom domain)
resource "google_compute_managed_ssl_certificate" "ssl_cert" {
  count = var.domain_name != "" ? 1 : 0
  name  = "${var.app_name}-ssl-cert-${var.environment}"

  managed {
    domains = [var.domain_name, "www.${var.domain_name}"]
  }
}

# Create backend service for Cloud Storage (frontend)
resource "google_compute_backend_bucket" "frontend_backend" {
  name        = "${var.app_name}-frontend-backend-${var.environment}"
  bucket_name = google_storage_bucket.frontend.name
  enable_cdn  = true

  cdn_policy {
    cache_mode                   = "CACHE_ALL_STATIC"
    default_ttl                 = 3600
    max_ttl                     = 86400
    negative_caching            = true
    serve_while_stale           = 86400
    signed_url_cache_max_age_sec = 7200

    # Cache key policy is managed automatically by GCP

    # Negative caching policy
    negative_caching_policy {
      code = 404
      ttl  = 120
    }
  }
}

# Create backend service for Cloud Run (API)
resource "google_compute_region_network_endpoint_group" "api_neg" {
  name                  = "${var.app_name}-api-neg-${var.environment}"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  
  cloud_run {
    service = google_cloud_run_v2_service.backend.name
  }
}

resource "google_compute_backend_service" "api_backend" {
  name                    = "${var.app_name}-api-backend-${var.environment}"
  protocol               = "HTTP"
  port_name              = "http"
  load_balancing_scheme  = "EXTERNAL"
  timeout_sec            = 30

  backend {
    group = google_compute_region_network_endpoint_group.api_neg.id
  }

  # Health check
  health_checks = [google_compute_health_check.api_health_check.id]

  # CDN configuration for API (optional, mainly for static responses)
  enable_cdn = false

  log_config {
    enable      = true
    sample_rate = var.environment == "prod" ? 0.1 : 1.0
  }
}

# Health check for API backend
resource "google_compute_health_check" "api_health_check" {
  name               = "${var.app_name}-api-health-${var.environment}"
  check_interval_sec = 10
  timeout_sec        = 5
  
  http_health_check {
    port               = 8080
    request_path       = "/health"
    response           = ""
  }
}

# URL map for routing traffic
resource "google_compute_url_map" "url_map" {
  name            = "${var.app_name}-url-map-${var.environment}"
  default_service = google_compute_backend_bucket.frontend_backend.id

  # Route API traffic to Cloud Run
  host_rule {
    hosts        = var.domain_name != "" ? [var.domain_name, "www.${var.domain_name}"] : ["*"]
    path_matcher = "main"
  }

  path_matcher {
    name            = "main"
    default_service = google_compute_backend_bucket.frontend_backend.id

    # API routes
    path_rule {
      paths   = ["/api/*", "/health"]
      service = google_compute_backend_service.api_backend.id
    }

    # Frontend routes (catch-all for SPA)
    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_bucket.frontend_backend.id
    }
  }
}

# HTTP(S) proxy
resource "google_compute_target_https_proxy" "https_proxy" {
  count   = var.domain_name != "" ? 1 : 0
  name    = "${var.app_name}-https-proxy-${var.environment}"
  url_map = google_compute_url_map.url_map.id
  
  ssl_certificates = [google_compute_managed_ssl_certificate.ssl_cert[0].id]
  
  # Security policy (optional)
  # ssl_policy = google_compute_ssl_policy.ssl_policy.id
}

# HTTP proxy (for redirect to HTTPS)
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "${var.app_name}-http-proxy-${var.environment}"
  url_map = google_compute_url_map.url_map.id
}

# Global forwarding rules
resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  count                 = var.domain_name != "" ? 1 : 0
  name                  = "${var.app_name}-https-forwarding-${var.environment}"
  ip_protocol          = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range           = "443"
  target               = google_compute_target_https_proxy.https_proxy[0].id
  ip_address           = google_compute_global_address.lb_ip.id
}

resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  name                  = "${var.app_name}-http-forwarding-${var.environment}"
  ip_protocol          = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range           = "80"
  target               = google_compute_target_http_proxy.http_proxy.id
  ip_address           = google_compute_global_address.lb_ip.id
}

# Cloud Armor security policy (optional)
resource "google_compute_security_policy" "security_policy" {
  name        = "${var.app_name}-security-policy-${var.environment}"
  description = "Security policy for ${var.app_name}"

  # Default rule
  rule {
    action   = "allow"
    priority = "2147483647"
    
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    
    description = "Default allow rule"
  }

  # Rate limiting rule
  rule {
    action   = "rate_based_ban"
    priority = "1000"
    
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      
      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
      
      ban_duration_sec = 300
    }
    
    description = "Rate limiting rule"
  }

  # Block common attacks
  rule {
    action   = "deny(403)"
    priority = "900"
    
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-stable')"
      }
    }
    
    description = "Block SQL injection attacks"
  }

  rule {
    action   = "deny(403)"
    priority = "901"
    
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-stable')"
      }
    }
    
    description = "Block XSS attacks"
  }
}

# SSL Policy for stronger security
resource "google_compute_ssl_policy" "ssl_policy" {
  name            = "${var.app_name}-ssl-policy-${var.environment}"
  profile         = "MODERN"
  min_tls_version = "TLS_1_2"
}