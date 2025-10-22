#!/bin/bash

# Simple Manual Trigger Creation
# This script creates Cloud Build triggers using local configuration files

PROJECT_ID=${1:-$(gcloud config get-value project)}

if [ -z "$PROJECT_ID" ]; then
    echo "Error: PROJECT_ID is required"
    echo "Usage: $0 PROJECT_ID"
    exit 1
fi

echo "Creating Cloud Build triggers for project: $PROJECT_ID"

# Create development trigger using local config
echo "Creating development trigger using cloudbuild-dev.yaml..."
cat > trigger-dev.json << EOF
{
  "name": "ecom-app-dev",
  "description": "Development environment deployment",
  "filename": "cloudbuild-dev.yaml",
  "github": {
    "owner": "eduardo239",
    "name": "app-ecom-gcp-dev",
    "push": {
      "branch": "^(develop|dev|feature/.*)$"
    }
  }
}
EOF

gcloud builds triggers import --source=trigger-dev.json --project=$PROJECT_ID && echo "✅ Dev trigger created" || echo "❌ Dev trigger failed"

# Create production trigger
echo "Creating production trigger using cloudbuild-prod.yaml..."
cat > trigger-prod.json << EOF
{
  "name": "ecom-app-prod", 
  "description": "Production environment deployment",
  "filename": "cloudbuild-prod.yaml",
  "github": {
    "owner": "eduardo239",
    "name": "app-ecom-gcp-dev",
    "push": {
      "branch": "^(main|master)$"
    }
  }
}
EOF

gcloud builds triggers import --source=trigger-prod.json --project=$PROJECT_ID && echo "✅ Prod trigger created" || echo "❌ Prod trigger failed"

# Create staging trigger
echo "Creating staging trigger using cloudbuild.yaml..."
cat > trigger-staging.json << EOF
{
  "name": "ecom-app-staging",
  "description": "Staging environment deployment (manual)",
  "filename": "cloudbuild.yaml",
  "substitutions": {
    "_ENVIRONMENT": "staging"
  },
  "github": {
    "owner": "eduardo239", 
    "name": "app-ecom-gcp-dev",
    "push": {
      "tag": "^v.*"
    }
  }
}
EOF

gcloud builds triggers import --source=trigger-staging.json --project=$PROJECT_ID && echo "✅ Staging trigger created" || echo "❌ Staging trigger failed"

# Clean up temporary files
rm -f trigger-dev.json trigger-prod.json trigger-staging.json

echo ""
echo "🏁 Trigger creation completed!"
echo ""
echo "📋 List of created triggers:"
gcloud builds triggers list --project=$PROJECT_ID --format="table(name,description,filename)" 2>/dev/null || echo "Could not list triggers"

echo ""
echo "🌐 View triggers in console:"
echo "https://console.cloud.google.com/cloud-build/triggers?project=$PROJECT_ID"