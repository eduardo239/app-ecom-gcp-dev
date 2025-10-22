#!/bin/bash

# Manual Cloud Build Trigger Setup
# Use this script when the automated setup fails

PROJECT_ID=${1:-$(gcloud config get-value project)}
REPO_OWNER=${2:-"eduardo239"}
REPO_NAME=${3:-"app-ecom-gcp-dev"}

echo "🔍 Debugging Cloud Build Triggers Setup"
echo "Project: $PROJECT_ID"
echo "Repository: $REPO_OWNER/$REPO_NAME"
echo ""

# Check current project
echo "📋 Current gcloud configuration:"
gcloud config list
echo ""

# Check if Cloud Build API is enabled
echo "🔌 Checking Cloud Build API status..."
if gcloud services list --enabled --filter="name:cloudbuild.googleapis.com" --format="value(name)" | grep -q cloudbuild; then
    echo "✅ Cloud Build API is enabled"
else
    echo "❌ Cloud Build API is not enabled"
    echo "Run: gcloud services enable cloudbuild.googleapis.com"
fi
echo ""

# List existing triggers
echo "📋 Current Cloud Build triggers:"
gcloud builds triggers list --project=$PROJECT_ID --format="table(name,github.owner,github.name,filename)" || echo "No triggers found or permission issue"
echo ""

# Check GitHub connections
echo "🔗 Checking GitHub connections..."
gcloud source repos list --format="table(name,url)" 2>/dev/null || echo "No source repositories connected"
echo ""

# Check Cloud Build permissions
echo "🔐 Checking Cloud Build service account permissions..."
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)" 2>/dev/null)
if [ -n "$PROJECT_NUMBER" ]; then
    CLOUD_BUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
    echo "Cloud Build Service Account: $CLOUD_BUILD_SA"
    
    echo ""
    echo "IAM bindings for Cloud Build SA:"
    gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" --format="table(bindings.role)" --filter="bindings.members:$CLOUD_BUILD_SA" 2>/dev/null || echo "Could not retrieve IAM bindings"
else
    echo "❌ Could not retrieve project number"
fi
echo ""

# Function to create trigger with error handling
create_trigger_with_debug() {
    local trigger_name=$1
    local branch_pattern=$2
    local build_config=$3
    local description=$4
    local tag_pattern=$5
    
    echo "🔨 Attempting to create trigger: $trigger_name"
    
    # Build the command
    local cmd="gcloud builds triggers create github"
    cmd+=" --repo-name=$REPO_NAME"
    cmd+=" --repo-owner=$REPO_OWNER"
    cmd+=" --build-config=$build_config"
    cmd+=" --name=$trigger_name"
    cmd+=" --description=\"$description\""
    cmd+=" --project=$PROJECT_ID"
    
    if [ -n "$branch_pattern" ]; then
        cmd+=" --branch-pattern=\"$branch_pattern\""
    fi
    
    if [ -n "$tag_pattern" ]; then
        cmd+=" --tag-pattern=\"$tag_pattern\""
    fi
    
    if [ "$trigger_name" = "ecom-app-staging" ]; then
        cmd+=" --substitutions=\"_ENVIRONMENT=staging\""
    fi
    
    echo "Command to execute:"
    echo "$cmd"
    echo ""
    
    # Execute the command
    if eval $cmd; then
        echo "✅ Successfully created trigger: $trigger_name"
    else
        echo "❌ Failed to create trigger: $trigger_name"
        echo "Error code: $?"
    fi
    echo ""
}

# Check if specific build config files exist
echo "📁 Checking build configuration files:"
for config in "cloudbuild.yaml" "cloudbuild-dev.yaml" "cloudbuild-prod.yaml"; do
    if [ -f "$config" ]; then
        echo "✅ $config exists"
    else
        echo "❌ $config not found"
    fi
done
echo ""

echo "🚀 Creating triggers with detailed error reporting..."
echo ""

# Create development trigger
create_trigger_with_debug "ecom-app-dev" "^develop$|^dev$|^feature/.*" "cloudbuild-dev.yaml" "Development environment deployment"

# Create production trigger  
create_trigger_with_debug "ecom-app-prod" "^main$|^master$" "cloudbuild-prod.yaml" "Production environment deployment"

# Create staging trigger
create_trigger_with_debug "ecom-app-staging" "" "cloudbuild.yaml" "Staging environment deployment (manual)" "v.*"

echo "🏁 Trigger creation completed"
echo ""

echo "📋 Final trigger list:"
gcloud builds triggers list --project=$PROJECT_ID --format="table(name,github.owner,github.name,filename,status)" 2>/dev/null || echo "Could not list triggers"
echo ""

echo "💡 If triggers still fail to create, try these manual steps:"
echo ""
echo "1. 🌐 Open Cloud Build Console:"
echo "   https://console.cloud.google.com/cloud-build/triggers?project=$PROJECT_ID"
echo ""
echo "2. 🔗 Connect GitHub repository:"
echo "   https://console.cloud.google.com/cloud-build/triggers/connect?project=$PROJECT_ID"
echo ""
echo "3. 📝 Create triggers manually using the UI with these settings:"
echo ""
echo "   Development Trigger:"
echo "   - Name: ecom-app-dev"
echo "   - Repository: $REPO_OWNER/$REPO_NAME"
echo "   - Branch: ^develop$|^dev$|^feature/.*"
echo "   - Build config: cloudbuild-dev.yaml"
echo ""
echo "   Production Trigger:"
echo "   - Name: ecom-app-prod"
echo "   - Repository: $REPO_OWNER/$REPO_NAME"
echo "   - Branch: ^main$|^master$"
echo "   - Build config: cloudbuild-prod.yaml"
echo ""
echo "   Staging Trigger:"
echo "   - Name: ecom-app-staging"
echo "   - Repository: $REPO_OWNER/$REPO_NAME"
echo "   - Tag: v.*"
echo "   - Build config: cloudbuild.yaml"
echo "   - Substitutions: _ENVIRONMENT=staging"