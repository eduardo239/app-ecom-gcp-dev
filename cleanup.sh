#!/bin/bash

# Cleanup Script for GCP E-commerce App
# This script will destroy all resources created for the e-commerce application

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration (modify these to match your deployment)
PROJECT_ID="app-xyz-dev"
REGION="us-central1"
BACKEND_SERVICE="ecom-backend"
FRONTEND_BUCKET="$PROJECT_ID-frontend"
DATABASE_INSTANCE="ecom-db"

print_warning "⚠️  DANGER: This will permanently delete ALL resources!"
print_warning "This includes:"
echo "  - Cloud Run services"
echo "  - Cloud SQL database (and ALL data)"
echo "  - Cloud Storage buckets (and ALL files)"
echo "  - Artifact Registry repositories"
echo "  - Load balancers and networking"
echo "  - Service accounts"
echo ""

read -p "Are you absolutely sure you want to destroy everything? Type 'DESTROY' to confirm: " confirmation

if [[ "$confirmation" != "DESTROY" ]]; then
    print_status "Cleanup cancelled. No resources were deleted."
    exit 0
fi

print_status "Starting resource cleanup for project: $PROJECT_ID"

# Set the project
gcloud config set project $PROJECT_ID

echo ""
print_status "🗑️  Destroying resources..."

# 1. Delete Cloud Run services
print_status "Deleting Cloud Run services..."
gcloud run services delete $BACKEND_SERVICE --region=$REGION --quiet 2>/dev/null || echo "Cloud Run service not found or already deleted"

# 2. Delete Cloud SQL instance
print_status "Deleting Cloud SQL database instance..."
print_warning "This will permanently delete ALL database data!"
gcloud sql instances delete $DATABASE_INSTANCE --quiet 2>/dev/null || echo "Database instance not found or already deleted"

# 3. Delete Cloud Storage buckets
print_status "Deleting Cloud Storage buckets..."
gsutil rm -r gs://$FRONTEND_BUCKET 2>/dev/null || echo "Frontend bucket not found or already deleted"
gsutil rm -r gs://$PROJECT_ID-ecom-app-assets-dev 2>/dev/null || echo "Assets bucket not found or already deleted"

# 4. Delete Artifact Registry repositories
print_status "Deleting Artifact Registry repositories..."
gcloud artifacts repositories delete $BACKEND_SERVICE --location=$REGION --quiet 2>/dev/null || echo "Artifact Registry repository not found or already deleted"

# 5. Delete Load Balancer components
print_status "Deleting Load Balancer and networking components..."

# Delete forwarding rules
gcloud compute forwarding-rules delete ecom-app-https-forwarding-dev --global --quiet 2>/dev/null || echo "HTTPS forwarding rule not found"
gcloud compute forwarding-rules delete ecom-app-http-forwarding-dev --global --quiet 2>/dev/null || echo "HTTP forwarding rule not found"

# Delete target proxies
gcloud compute target-https-proxies delete ecom-app-https-proxy-dev --quiet 2>/dev/null || echo "HTTPS proxy not found"
gcloud compute target-http-proxies delete ecom-app-http-proxy-dev --quiet 2>/dev/null || echo "HTTP proxy not found"

# Delete SSL certificates
gcloud compute ssl-certificates delete ecom-app-ssl-cert-dev --quiet 2>/dev/null || echo "SSL certificate not found"

# Delete URL map
gcloud compute url-maps delete ecom-app-url-map-dev --quiet 2>/dev/null || echo "URL map not found"

# Delete backend services
gcloud compute backend-services delete ecom-app-api-backend-dev --global --quiet 2>/dev/null || echo "API backend service not found"

# Delete backend buckets
gcloud compute backend-buckets delete ecom-app-frontend-backend-dev --quiet 2>/dev/null || echo "Frontend backend bucket not found"

# Delete health checks
gcloud compute health-checks delete ecom-app-api-health-dev --quiet 2>/dev/null || echo "Health check not found"

# Delete network endpoint groups
gcloud compute network-endpoint-groups delete ecom-app-api-neg-dev --region=$REGION --quiet 2>/dev/null || echo "Network endpoint group not found"

# Delete global IP address
gcloud compute addresses delete ecom-app-lb-ip-dev --global --quiet 2>/dev/null || echo "Global IP address not found"

# 6. Delete VPC components
print_status "Deleting VPC and networking..."

# Delete VPC connector
gcloud compute networks vpc-access connectors delete ecom-app-vpc-connector-dev --region=$REGION --quiet 2>/dev/null || echo "VPC connector not found"

# Delete subnets
gcloud compute networks subnets delete ecom-app-subnet-dev --region=$REGION --quiet 2>/dev/null || echo "Subnet not found"

# Delete VPC network
gcloud compute networks delete ecom-app-vpc-dev --quiet 2>/dev/null || echo "VPC network not found"

# 7. Delete Service Accounts
print_status "Deleting Service Accounts..."
gcloud iam service-accounts delete ecom-app-cloudrun-dev@$PROJECT_ID.iam.gserviceaccount.com --quiet 2>/dev/null || echo "Cloud Run SA not found"
gcloud iam service-accounts delete ecom-app-cloudbuild-dev@$PROJECT_ID.iam.gserviceaccount.com --quiet 2>/dev/null || echo "Cloud Build SA not found"
gcloud iam service-accounts delete ecom-app-frontend-deploy-dev@$PROJECT_ID.iam.gserviceaccount.com --quiet 2>/dev/null || echo "Frontend deployer SA not found"

# 8. Delete Secret Manager secrets
print_status "Deleting Secret Manager secrets..."
gcloud secrets delete ecom-app-db-password-dev --quiet 2>/dev/null || echo "Database password secret not found"
gcloud secrets delete ecom-app-dev-sa-key-dev --quiet 2>/dev/null || echo "Service account key secret not found"

# 9. Clean up IAM policies and custom roles
print_status "Cleaning up IAM roles..."
gcloud iam roles delete ecom_app_backend_minimal_dev --project=$PROJECT_ID --quiet 2>/dev/null || echo "Custom IAM role not found"

echo ""
print_success "✅ Resource cleanup completed!"
print_warning "Note: Some resources might take a few minutes to be fully deleted."
print_status "Remaining cleanup steps you might need to do manually:"
echo "  1. Check for any remaining resources in the GCP Console"
echo "  2. Verify billing is stopped for deleted resources"
echo "  3. Remove any DNS records pointing to the old IP address"
echo "  4. Clean up any local Docker images: docker system prune -a"

echo ""
print_status "To verify all resources are deleted, check:"
echo "  • Cloud Console: https://console.cloud.google.com/home/dashboard?project=$PROJECT_ID"
echo "  • Billing: https://console.cloud.google.com/billing"