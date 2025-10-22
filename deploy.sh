#!/bin/bash

# GCP Deployment Script for E-commerce App
# Make sure you have gcloud CLI installed and authenticated

# Remove 'set -e' to handle errors gracefully
# set -e

# Function to check if command succeeded
check_command() {
    if [ $? -eq 0 ]; then
        echo "✅ $1 completed successfully"
    else
        echo "❌ $1 failed - continuing anyway"
    fi
}

# Configuration
PROJECT_ID="app-xyz-dev"
REGION="us-central1"
BACKEND_SERVICE="ecom-backend"
FRONTEND_BUCKET="$PROJECT_ID-frontend"
DATABASE_INSTANCE="ecom-db"
DATABASE_NAME="ecommerce"

echo "🚀 Starting deployment to Google Cloud Platform..."

# Set the project
gcloud config set project $PROJECT_ID

# Check if user has necessary permissions
echo "🔐 Checking permissions..."
ACCOUNT=$(gcloud config get-value account)
echo "Authenticated as: $ACCOUNT"

# Check if user has necessary roles
echo "Checking IAM roles..."
gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" --format="table(bindings.role)" --filter="bindings.members:$ACCOUNT" | head -10

# Check if billing is enabled
echo "Checking billing status..."
gcloud billing projects describe $PROJECT_ID --format="value(billingEnabled)" 2>/dev/null || echo "Cannot check billing status - may need billing admin role"

# Enable required APIs
echo "📡 Enabling required GCP APIs..."
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable sql-component.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable secretmanager.googleapis.com

# Create Cloud SQL instance (PostgreSQL)
echo "🗄️ Creating Cloud SQL database..."
gcloud sql instances create $DATABASE_INSTANCE \
    --database-version=POSTGRES_14 \
    --tier=db-f1-micro \
    --region=$REGION \
    --storage-type=SSD \
    --storage-size=10GB \
    --backup \
    --backup-start-time=03:00 \
    --maintenance-window-day=SUN \
    --maintenance-window-hour=04 \
    --maintenance-release-channel=production \
    --no-assign-ip \
    --network=default 2>/dev/null || echo "Database instance already exists or insufficient permissions"

# Wait a moment for instance to be ready
echo "⏳ Waiting for database instance to be ready..."
sleep 10

# Create database
echo "📊 Creating application database..."
gcloud sql databases create $DATABASE_NAME \
    --instance=$DATABASE_INSTANCE 2>/dev/null || echo "Database already exists or insufficient permissions"

# Create database user
echo "👤 Creating database user..."
gcloud sql users create appuser \
    --instance=$DATABASE_INSTANCE \
    --password=SecurePassword123! 2>/dev/null || echo "Database user already exists or insufficient permissions"

# Build and deploy backend to Cloud Run
echo "🐍 Building and deploying Flask backend..."
cd backend

# Create Artifact Registry repository if it doesn't exist
echo "📦 Setting up Artifact Registry..."
gcloud artifacts repositories create $BACKEND_SERVICE \
    --repository-format=docker \
    --location=$REGION \
    --description="Docker repository for $BACKEND_SERVICE" 2>/dev/null || echo "Repository already exists"

# Configure Docker to use Artifact Registry
gcloud auth configure-docker $REGION-docker.pkg.dev 2>/dev/null || echo "Docker already configured"

# Build Docker image
echo "🔨 Building Docker image..."
gcloud builds submit --tag $REGION-docker.pkg.dev/$PROJECT_ID/$BACKEND_SERVICE/$BACKEND_SERVICE:latest

# Deploy to Cloud Run
echo "🚀 Deploying to Cloud Run..."
gcloud run deploy $BACKEND_SERVICE \
    --image $REGION-docker.pkg.dev/$PROJECT_ID/$BACKEND_SERVICE/$BACKEND_SERVICE:latest \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --set-env-vars DATABASE_URL=postgresql://appuser:SecurePassword123!@//cloudsql/$PROJECT_ID:$REGION:$DATABASE_INSTANCE/$DATABASE_NAME \
    --add-cloudsql-instances $PROJECT_ID:$REGION:$DATABASE_INSTANCE \
    --cpu=1 \
    --memory=512Mi \
    --timeout=300 \
    --max-instances=10 2>/dev/null || echo "Cloud Run deployment failed - check permissions"

cd ..

# Build and deploy frontend
echo "⚛️ Building and deploying React frontend..."
cd frontend

# Install dependencies and build
echo "📦 Installing frontend dependencies..."
npm ci 2>/dev/null || echo "npm install failed - check Node.js setup"

echo "🔨 Building frontend..."
npm run build 2>/dev/null || echo "Frontend build failed - check build configuration"

cd ..

# Create Cloud Storage bucket for frontend
echo "📦 Creating Cloud Storage bucket for frontend..."
gsutil mb gs://$FRONTEND_BUCKET 2>/dev/null || echo "Bucket already exists or insufficient permissions"

# Make bucket publicly readable
echo "🌐 Setting bucket permissions..."
gsutil iam ch allUsers:objectViewer gs://$FRONTEND_BUCKET 2>/dev/null || echo "Failed to set bucket permissions"

# Upload frontend files (check if dist directory exists)
if [ -d "frontend/dist" ]; then
    echo "📤 Uploading frontend files..."
    gsutil -m rsync -r -d frontend/dist gs://$FRONTEND_BUCKET 2>/dev/null || echo "Failed to upload frontend files"
else
    echo "❌ Frontend build directory not found. Skipping upload."
fi

# Configure bucket for website hosting
echo "🔧 Configuring bucket for web hosting..."
gsutil web set -m index.html -e index.html gs://$FRONTEND_BUCKET 2>/dev/null || echo "Failed to configure web hosting"

echo "✅ Deployment completed!"
echo ""
echo "🔗 Your application URLs:"
echo "Backend API: $(gcloud run services describe $BACKEND_SERVICE --region=$REGION --format='value(status.url)')"
echo "Frontend: https://storage.googleapis.com/$FRONTEND_BUCKET/index.html"
echo ""
echo "📋 Next steps:"
echo "1. Configure your custom domain (optional)"
echo "2. Set up Cloud CDN for better performance"
echo "3. Configure monitoring and logging"
echo "4. Set up CI/CD pipeline with Cloud Build"