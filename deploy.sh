#!/bin/bash

# GCP Deployment Script for E-commerce App
# Make sure you have gcloud CLI installed and authenticated

set -e

# Configuration
PROJECT_ID="your-gcp-project-id"
REGION="us-central1"
BACKEND_SERVICE="ecom-backend"
FRONTEND_BUCKET="$PROJECT_ID-frontend"
DATABASE_INSTANCE="ecom-db"
DATABASE_NAME="ecommerce"

echo "🚀 Starting deployment to Google Cloud Platform..."

# Set the project
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "📡 Enabling required GCP APIs..."
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable sql-component.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable cdn.googleapis.com

# Create Cloud SQL instance (PostgreSQL)
echo "🗄️ Creating Cloud SQL database..."
gcloud sql instances create $DATABASE_INSTANCE \
    --database-version=POSTGRES_14 \
    --tier=db-f1-micro \
    --region=$REGION \
    --storage-type=SSD \
    --storage-size=10GB \
    --backup \
    --enable-bin-log || echo "Database instance already exists"

# Create database
gcloud sql databases create $DATABASE_NAME \
    --instance=$DATABASE_INSTANCE || echo "Database already exists"

# Create database user
gcloud sql users create appuser \
    --instance=$DATABASE_INSTANCE \
    --password=SecurePassword123!

# Build and deploy backend to Cloud Run
echo "🐍 Building and deploying Flask backend..."
cd backend

# Build Docker image
gcloud builds submit --tag gcr.io/$PROJECT_ID/$BACKEND_SERVICE

# Deploy to Cloud Run
gcloud run deploy $BACKEND_SERVICE \
    --image gcr.io/$PROJECT_ID/$BACKEND_SERVICE \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --set-env-vars DATABASE_URL=postgresql://appuser:SecurePassword123!@//cloudsql/$PROJECT_ID:$REGION:$DATABASE_INSTANCE/$DATABASE_NAME \
    --add-cloudsql-instances $PROJECT_ID:$REGION:$DATABASE_INSTANCE

cd ..

# Build and deploy frontend
echo "⚛️ Building and deploying React frontend..."
cd frontend

# Install dependencies and build
npm ci
npm run build

cd ..

# Create Cloud Storage bucket for frontend
echo "📦 Creating Cloud Storage bucket..."
gsutil mb gs://$FRONTEND_BUCKET || echo "Bucket already exists"

# Make bucket publicly readable
gsutil iam ch allUsers:objectViewer gs://$FRONTEND_BUCKET

# Upload frontend files
gsutil -m rsync -r -d frontend/dist gs://$FRONTEND_BUCKET

# Configure bucket for website hosting
gsutil web set -m index.html -e index.html gs://$FRONTEND_BUCKET

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