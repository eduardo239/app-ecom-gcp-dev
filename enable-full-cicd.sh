#!/bin/bash

# Complete CI/CD Setup Script
echo "🚀 Setting up complete CI/CD for your repository"

PROJECT_ID="app-xyz-dev"
CURRENT_USER=$(gcloud config get-value account 2>/dev/null)

echo "Project: $PROJECT_ID"
echo "Current user: $CURRENT_USER"
echo ""

# Step 1: Create service account for GitHub Actions
echo "1️⃣ Creating GitHub Actions service account..."
gcloud iam service-accounts create github-actions \
    --description="GitHub Actions deployment" \
    --display-name="GitHub Actions" \
    --project=$PROJECT_ID 2>/dev/null || echo "Service account already exists"

# Step 2: Grant necessary roles
echo "2️⃣ Granting roles to service account..."
SA_EMAIL="github-actions@$PROJECT_ID.iam.gserviceaccount.com"

for role in "roles/run.admin" "roles/storage.admin" "roles/artifactregistry.writer" "roles/cloudsql.client"; do
    echo "Granting $role..."
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$SA_EMAIL" \
        --role="$role" \
        --quiet
done

# Step 3: Create and download service account key
echo "3️⃣ Creating service account key..."
KEY_FILE="github-actions-key.json"
gcloud iam service-accounts keys create $KEY_FILE \
    --iam-account=$SA_EMAIL \
    --project=$PROJECT_ID

if [ -f "$KEY_FILE" ]; then
    echo "✅ Service account key created: $KEY_FILE"
    echo ""
    echo "📋 GitHub Secrets to Add:"
    echo "================================"
    echo "Secret Name: GCP_PROJECT_ID"
    echo "Value: $PROJECT_ID"
    echo ""
    echo "Secret Name: GCP_SA_KEY"
    echo "Value: (copy the entire content below)"
    echo "--------------------------------"
    cat $KEY_FILE
    echo "--------------------------------"
    echo ""
    echo "🔗 Add secrets at:"
    echo "https://github.com/eduardo239/app-ecom-gcp-dev/settings/secrets/actions"
    
    # Clean up the key file for security
    rm -f $KEY_FILE
    echo "🗑️ Key file cleaned up for security"
else
    echo "❌ Failed to create service account key"
fi

echo ""
echo "4️⃣ Next steps:"
echo "1. Add the GitHub secrets above"
echo "2. Enable full deployment in GitHub Actions"
echo "3. Push to develop branch to test"