#!/bin/bash

# Cloud Build CI/CD Setup Script
# This script sets up Cloud Build triggers for automated deployments

set -e

PROJECT_ID=${1:-$(gcloud config get-value project)}
REPO_OWNER=${2:-"eduardo239"}
REPO_NAME=${3:-"app-ecom-gcp-dev"}
REGION=${4:-"us-central1"}

if [ -z "$PROJECT_ID" ]; then
    echo "Error: PROJECT_ID is required"
    echo "Usage: $0 [PROJECT_ID] [REPO_OWNER] [REPO_NAME] [REGION]"
    exit 1
fi

echo "Setting up CI/CD pipeline for project: $PROJECT_ID"
echo "Repository: $REPO_OWNER/$REPO_NAME"
echo "Region: $REGION"

# Enable required APIs
echo "Enabling required APIs..."
gcloud services enable cloudbuild.googleapis.com \
    run.googleapis.com \
    artifactregistry.googleapis.com \
    secretmanager.googleapis.com \
    storage.googleapis.com \
    --project=$PROJECT_ID

# Create Artifact Registry repository
echo "Creating Artifact Registry repository..."
gcloud artifacts repositories create ecom-app \
    --repository-format=docker \
    --location=$REGION \
    --description="E-commerce app container images" \
    --project=$PROJECT_ID || echo "Repository already exists"

# Grant Cloud Build permissions
echo "Setting up Cloud Build permissions..."
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
CLOUD_BUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

# Grant necessary roles to Cloud Build service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${CLOUD_BUILD_SA}" \
    --role="roles/run.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${CLOUD_BUILD_SA}" \
    --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${CLOUD_BUILD_SA}" \
    --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${CLOUD_BUILD_SA}" \
    --role="roles/secretmanager.secretAccessor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${CLOUD_BUILD_SA}" \
    --role="roles/iam.serviceAccountUser"

# Create database URL secret (placeholder)
echo "Creating database URL secret..."
echo "postgresql://user:password@localhost/ecom_db" | \
    gcloud secrets create database-url --data-file=- --project=$PROJECT_ID || \
    echo "Secret already exists"

# Create development trigger
echo "Creating development trigger..."
gcloud builds triggers create github \
    --repo-name=$REPO_NAME \
    --repo-owner=$REPO_OWNER \
    --branch-pattern="^develop$|^dev$|^feature/.*" \
    --build-config=cloudbuild-dev.yaml \
    --name="ecom-app-dev" \
    --description="Development environment deployment" \
    --project=$PROJECT_ID || echo "Dev trigger already exists"

# Create production trigger
echo "Creating production trigger..."
gcloud builds triggers create github \
    --repo-name=$REPO_NAME \
    --repo-owner=$REPO_OWNER \
    --branch-pattern="^main$|^master$" \
    --build-config=cloudbuild-prod.yaml \
    --name="ecom-app-prod" \
    --description="Production environment deployment" \
    --project=$PROJECT_ID || echo "Prod trigger already exists"

# Create manual staging trigger
echo "Creating staging trigger..."
gcloud builds triggers create github \
    --repo-name=$REPO_NAME \
    --repo-owner=$REPO_OWNER \
    --tag-pattern="v.*" \
    --build-config=cloudbuild.yaml \
    --name="ecom-app-staging" \
    --description="Staging environment deployment (manual)" \
    --substitutions="_ENVIRONMENT=staging" \
    --project=$PROJECT_ID || echo "Staging trigger already exists"

echo "✅ CI/CD pipeline setup completed!"
echo ""
echo "🚀 Triggers created:"
echo "  - Development: Triggered on 'develop', 'dev', or 'feature/*' branches"
echo "  - Production: Triggered on 'main' or 'master' branch"
echo "  - Staging: Triggered on tags matching 'v.*' (e.g., v1.0.0)"
echo ""
echo "📝 Next steps:"
echo "  1. Connect your GitHub repository to Cloud Build"
echo "  2. Update the database URL secret with your actual database connection"
echo "  3. Push code to trigger your first build"
echo ""
echo "🔧 Manual trigger example:"
echo "  gcloud builds submit --config cloudbuild.yaml --project=$PROJECT_ID"
echo ""
echo "🌐 Monitor builds at: https://console.cloud.google.com/cloud-build/builds?project=$PROJECT_ID"