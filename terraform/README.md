# Terraform Infrastructure for GCP E-commerce App

This directory contains Terraform configurations to deploy a complete e-commerce application infrastructure on Google Cloud Platform.

## 🏗️ Architecture Overview

The infrastructure includes:

- **Frontend**: React app hosted on Cloud Storage + Cloud CDN
- **Backend**: Flask API on Cloud Run (serverless)
- **Database**: Cloud SQL PostgreSQL (private networking)
- **Security**: IAM, VPC, SSL certificates, Cloud Armor
- **CI/CD**: Cloud Build, Artifact Registry
- **Monitoring**: Cloud Logging, Cloud Monitoring

## 📁 File Structure

```
terraform/
├── main.tf              # Main configuration and provider settings
├── variables.tf         # Input variables definition
├── outputs.tf           # Output values
├── database.tf          # Cloud SQL database configuration
├── cloudrun.tf          # Cloud Run service configuration
├── storage.tf           # Cloud Storage buckets
├── iam.tf              # IAM roles and service accounts
├── networking.tf        # Load balancer, CDN, networking
├── terraform.tfvars.example  # Example variables file
├── deploy.sh           # Interactive deployment script
└── README.md           # This file
```

## 🚀 Quick Start

### Prerequisites

1. **Install Required Tools:**

   ```bash
   # Install Terraform
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/

   # Install Google Cloud SDK
   curl https://sdk.cloud.google.com | bash
   exec -l $SHELL
   ```

2. **Setup GCP Project:**

   ```bash
   # Login to Google Cloud
   gcloud auth login

   # Set your project ID
   gcloud config set project YOUR_PROJECT_ID

   # Enable billing on your project (required)
   ```

3. **Configure Terraform Variables:**

   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars

   # Edit terraform.tfvars with your project details
   nano terraform.tfvars
   ```

### Deploy Using Interactive Script

The easiest way to deploy is using the interactive script:

```bash
./deploy.sh
```

This script will guide you through:

1. Prerequisites check
2. Terraform initialization
3. Planning the deployment
4. Applying the infrastructure
5. Showing deployment information

### Manual Deployment

If you prefer manual control:

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -out=tfplan

# Apply the infrastructure
terraform apply tfplan

# View outputs
terraform output
```

## 📋 Configuration Options

### Required Variables

```hcl
project_id = "your-gcp-project-id"  # Your GCP project ID
```

### Optional Variables

```hcl
# Environment and naming
environment = "dev"                  # dev, staging, prod
app_name    = "ecom-app"            # Application name
region      = "us-central1"         # GCP region
zone        = "us-central1-a"       # GCP zone

# Database configuration
database_tier    = "db-f1-micro"    # Cloud SQL tier
database_version = "POSTGRES_14"    # PostgreSQL version
database_name    = "ecommerce"      # Database name
database_user    = "appuser"        # Database user

# Cloud Run configuration
max_instances = 10                   # Max Cloud Run instances
cpu_limit     = "1000m"             # CPU limit (1 CPU)
memory_limit  = "512Mi"             # Memory limit (512MB)

# Custom domain (optional)
domain_name = "yourdomain.com"      # Custom domain

# Labels for resource organization
labels = {
  application = "ecommerce"
  environment = "dev"
  team       = "development"
  managed-by = "terraform"
}
```

## 🔒 Security Features

- **Private Networking**: Database isolated in private VPC
- **IAM**: Least-privilege service accounts
- **SSL/TLS**: Managed SSL certificates for HTTPS
- **Cloud Armor**: DDoS protection and WAF rules
- **Secret Management**: Database passwords in Secret Manager
- **Audit Logging**: Comprehensive audit trails

## 💰 Cost Optimization

### Development Environment (~$15-30/month)

- Cloud SQL: db-f1-micro instance
- Cloud Run: Pay-per-use (scales to zero)
- Cloud Storage: Minimal storage costs
- Cloud CDN: Low traffic costs

### Production Environment (~$50-200/month)

- Cloud SQL: Higher tier instances with regional availability
- Enhanced monitoring and logging
- Multiple environments
- Advanced security features

## 📊 Monitoring and Logging

The infrastructure automatically configures:

- **Cloud Monitoring**: Application and infrastructure metrics
- **Cloud Logging**: Centralized log management
- **Error Reporting**: Automatic error detection
- **Uptime Monitoring**: Service availability checks

## 🔄 CI/CD Integration

The infrastructure includes:

- **Cloud Build**: Automated building and deployment
- **Artifact Registry**: Container image storage
- **Service Accounts**: Proper permissions for CI/CD
- **Cloud Source Repositories**: Git integration

## 🌐 Domain Configuration

To use a custom domain:

1. Set `domain_name` in `terraform.tfvars`
2. After deployment, configure DNS:

   ```bash
   # Get the load balancer IP
   terraform output load_balancer_ip

   # Point your domain's A record to this IP
   ```

3. SSL certificates are automatically provisioned

## 📈 Scaling Configuration

### Horizontal Scaling

- Cloud Run: Auto-scales based on traffic
- Database: Use read replicas for read-heavy workloads
- CDN: Automatically scales globally

### Vertical Scaling

- Increase Cloud Run CPU/memory limits
- Upgrade Cloud SQL instance tier
- Use multiple regions for global deployment

## 🔧 Troubleshooting

### Common Issues

1. **API Not Enabled**:

   ```bash
   gcloud services enable <service-name>
   ```

2. **Permissions Error**:

   ```bash
   gcloud auth application-default login
   ```

3. **Resource Quota**:
   Check GCP Console for quota limits and request increases

4. **Domain SSL Issues**:
   Ensure DNS is pointing to the correct IP before SSL certificate provisioning

### Debugging

```bash
# Check Terraform state
terraform show

# Debug specific resources
terraform state show google_cloud_run_v2_service.backend

# View logs
gcloud logging read "resource.type=cloud_run_revision"
```

## 🧹 Cleanup

To destroy all resources:

```bash
# Using the script
./deploy.sh  # Choose option 5

# Or manually
terraform destroy
```

⚠️ **Warning**: This will permanently delete all resources and data.

## 📚 Additional Resources

- [Terraform GCP Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Google Cloud Architecture Center](https://cloud.google.com/architecture)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud SQL Documentation](https://cloud.google.com/sql/docs)

## 🆘 Support

If you encounter issues:

1. Check the [troubleshooting section](#troubleshooting)
2. Review Terraform and GCP logs
3. Consult the official documentation
4. Check GCP Console for resource status

## 📝 License

This infrastructure code is provided as-is for educational and development purposes.
