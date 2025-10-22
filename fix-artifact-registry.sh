#!/bin/bash

# Artifact Registry Permission Fix Script
PROJECT_ID=${1:-"app-xyz-dev"}
REGION=${2:-"us-central1"}
REPO_NAME=${3:-"ecom-app"}

echo "🔍 Diagnosing Artifact Registry Permission Issue"
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Repository: $REPO_NAME"
echo ""

# Check current gcloud configuration
echo "📋 Current gcloud configuration:"
gcloud config list 2>/dev/null || echo "❌ gcloud not configured or not authenticated"
echo ""

echo "🔐 Current authentication:"
gcloud auth list 2>/dev/null || echo "❌ No authentication found"
echo ""

# Check if Artifact Registry API is enabled
echo "🔌 Checking Artifact Registry API:"
if gcloud services list --enabled --filter="name:artifactregistry.googleapis.com" --format="value(name)" --project=$PROJECT_ID 2>/dev/null | grep -q artifactregistry; then
    echo "✅ Artifact Registry API is enabled"
else
    echo "❌ Artifact Registry API is not enabled"
    echo "🔧 Enabling Artifact Registry API..."
    gcloud services enable artifactregistry.googleapis.com --project=$PROJECT_ID || echo "Failed to enable API"
fi
echo ""

# Check if repository exists
echo "📦 Checking if repository exists:"
if gcloud artifacts repositories describe $REPO_NAME --location=$REGION --project=$PROJECT_ID >/dev/null 2>&1; then
    echo "✅ Repository '$REPO_NAME' exists"
else
    echo "❌ Repository '$REPO_NAME' does not exist"
    echo "🔧 Creating Artifact Registry repository..."
    gcloud artifacts repositories create $REPO_NAME \
        --repository-format=docker \
        --location=$REGION \
        --description="E-commerce app container images" \
        --project=$PROJECT_ID && echo "✅ Repository created" || echo "❌ Failed to create repository"
fi
echo ""

# List all repositories to verify
echo "📋 All Artifact Registry repositories:"
gcloud artifacts repositories list --project=$PROJECT_ID 2>/dev/null || echo "Could not list repositories"
echo ""

# Check current user permissions
echo "🔐 Checking IAM permissions:"
CURRENT_USER=$(gcloud config get-value account 2>/dev/null)
if [ -n "$CURRENT_USER" ]; then
    echo "Current user: $CURRENT_USER"
    
    # Check if user has necessary roles
    echo "Checking roles for current user..."
    gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" --format="table(bindings.role)" --filter="bindings.members:$CURRENT_USER" 2>/dev/null || echo "Could not check user roles"
else
    echo "❌ Could not determine current user"
fi
echo ""

# Grant necessary permissions to current user
echo "🔧 Granting necessary permissions to current user..."
if [ -n "$CURRENT_USER" ]; then
    for role in "roles/artifactregistry.admin" "roles/storage.admin" "roles/run.admin"; do
        echo "Granting $role to $CURRENT_USER..."
        gcloud projects add-iam-policy-binding $PROJECT_ID \
            --member="user:$CURRENT_USER" \
            --role="$role" \
            --quiet 2>/dev/null && echo "✅ $role granted" || echo "⚠️ Could not grant $role (may already exist)"
    done
fi
echo ""

# Configure Docker authentication
echo "🐳 Configuring Docker authentication:"
gcloud auth configure-docker $REGION-docker.pkg.dev --quiet && echo "✅ Docker authentication configured" || echo "❌ Docker authentication failed"
echo ""

# Test Docker authentication
echo "🧪 Testing Docker authentication:"
DOCKER_TAG="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/test:latest"
echo "Test tag: $DOCKER_TAG"

# Create a simple test image
echo "Creating test image..."
cat > Dockerfile.test << EOF
FROM alpine:latest
RUN echo "Test image for Artifact Registry"
EOF

docker build -t $DOCKER_TAG -f Dockerfile.test . >/dev/null 2>&1 && echo "✅ Test image built" || echo "❌ Test image build failed"

# Try to push test image
echo "Testing push to Artifact Registry..."
if docker push $DOCKER_TAG >/dev/null 2>&1; then
    echo "✅ Push to Artifact Registry successful!"
    # Clean up test image
    gcloud artifacts docker images delete $DOCKER_TAG --quiet 2>/dev/null || echo "Could not delete test image"
else
    echo "❌ Push to Artifact Registry failed"
    echo ""
    echo "🔧 Additional troubleshooting steps:"
    echo "1. Verify project ID: $PROJECT_ID"
    echo "2. Verify you have Owner or Editor role in the project"
    echo "3. Try: gcloud auth application-default login"
    echo "4. Try: gcloud auth login --update-adc"
fi

# Clean up test files
rm -f Dockerfile.test

echo ""
echo "📋 Summary of required setup:"
echo "✓ Enable Artifact Registry API"
echo "✓ Create repository: $REPO_NAME"
echo "✓ Grant permissions to user: $CURRENT_USER"
echo "✓ Configure Docker authentication"
echo ""
echo "🚀 To manually create repository and set permissions:"
echo "gcloud services enable artifactregistry.googleapis.com --project=$PROJECT_ID"
echo "gcloud artifacts repositories create $REPO_NAME --repository-format=docker --location=$REGION --project=$PROJECT_ID"
echo "gcloud projects add-iam-policy-binding $PROJECT_ID --member=\"user:$CURRENT_USER\" --role=\"roles/artifactregistry.admin\""
echo "gcloud auth configure-docker $REGION-docker.pkg.dev"