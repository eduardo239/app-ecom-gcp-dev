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

# Function to check if GitHub app is connected
check_github_connection() {
    echo "Checking GitHub App connection..."
    REPOS=$(gcloud source repos list --format="value(name)" 2>/dev/null || echo "")
    if [[ $REPOS == *"github_${REPO_OWNER}_${REPO_NAME}"* ]]; then
        echo "✅ GitHub repository is connected"
        return 0
    else
        echo "❌ GitHub repository not connected"
        return 1
    fi
}

# Function to delete existing trigger if it exists
delete_trigger_if_exists() {
    local trigger_name=$1
    echo "Checking for existing trigger: $trigger_name"
    
    if gcloud builds triggers describe $trigger_name --project=$PROJECT_ID >/dev/null 2>&1; then
        echo "Deleting existing trigger: $trigger_name"
        gcloud builds triggers delete $trigger_name --project=$PROJECT_ID --quiet
    fi
}

# Enable required APIs
echo "Enabling required APIs..."
gcloud services enable cloudbuild.googleapis.com \
    run.googleapis.com \
    artifactregistry.googleapis.com \
    secretmanager.googleapis.com \
    storage.googleapis.com \
    sourcerepo.googleapis.com \
    --project=$PROJECT_ID

# Create Artifact Registry repository
echo "Creating Artifact Registry repository..."
gcloud artifacts repositories create ecom-app \
    --repository-format=docker \
    --location=$REGION \
    --description="E-commerce app container images" \
    --project=$PROJECT_ID 2>/dev/null || echo "Repository already exists"

# Grant Cloud Build permissions
echo "Setting up Cloud Build permissions..."
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
CLOUD_BUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

# Grant necessary roles to Cloud Build service account
for role in "roles/run.admin" "roles/storage.admin" "roles/artifactregistry.writer" "roles/secretmanager.secretAccessor" "roles/iam.serviceAccountUser" "roles/source.admin"; do
    echo "Granting $role to Cloud Build service account..."
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:${CLOUD_BUILD_SA}" \
        --role="$role" \
        --quiet || echo "Role already granted or error occurred"
done

# Create database URL secret (placeholder)
echo "Creating database URL secret..."
echo "postgresql://user:password@localhost/ecom_db" | \
    gcloud secrets create database-url --data-file=- --project=$PROJECT_ID 2>/dev/null || \
    echo "Secret already exists"

# Check GitHub connection first
if ! check_github_connection; then
    echo ""
    echo "⚠️  GitHub repository not connected to Cloud Build!"
    echo ""
    echo "Please follow these steps to connect your GitHub repository:"
    echo "1. Go to: https://console.cloud.google.com/cloud-build/triggers/connect?project=$PROJECT_ID"
    echo "2. Select 'GitHub (Cloud Build GitHub App)'"
    echo "3. Authenticate with GitHub and select repository: $REPO_OWNER/$REPO_NAME"
    echo "4. Re-run this script after connecting"
    echo ""
    echo "Alternatively, you can create triggers manually in the Cloud Console:"
    echo "https://console.cloud.google.com/cloud-build/triggers?project=$PROJECT_ID"
    exit 1
fi

# Delete existing triggers to avoid conflicts
delete_trigger_if_exists "ecom-app-dev"
delete_trigger_if_exists "ecom-app-prod" 
delete_trigger_if_exists "ecom-app-staging"

# Create development trigger
echo "Creating development trigger..."
if gcloud builds triggers create github \
    --repo-name=$REPO_NAME \
    --repo-owner=$REPO_OWNER \
    --branch-pattern="^develop$|^dev$|^feature/.*" \
    --build-config=cloudbuild-dev.yaml \
    --name="ecom-app-dev" \
    --description="Development environment deployment" \
    --project=$PROJECT_ID; then
    echo "✅ Development trigger created successfully"
else
    echo "❌ Failed to create development trigger"
fi

# Create production trigger
echo "Creating production trigger..."
if gcloud builds triggers create github \
    --repo-name=$REPO_NAME \
    --repo-owner=$REPO_OWNER \
    --branch-pattern="^main$|^master$" \
    --build-config=cloudbuild-prod.yaml \
    --name="ecom-app-prod" \
    --description="Production environment deployment" \
    --project=$PROJECT_ID; then
    echo "✅ Production trigger created successfully"
else
    echo "❌ Failed to create production trigger"
fi

# Create manual staging trigger
echo "Creating staging trigger..."
if gcloud builds triggers create github \
    --repo-name=$REPO_NAME \
    --repo-owner=$REPO_OWNER \
    --tag-pattern="v.*" \
    --build-config=cloudbuild.yaml \
    --name="ecom-app-staging" \
    --description="Staging environment deployment (manual)" \
    --substitutions="_ENVIRONMENT=staging" \
    --project=$PROJECT_ID; then
    echo "✅ Staging trigger created successfully"
else
    echo "❌ Failed to create staging trigger"
fi

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