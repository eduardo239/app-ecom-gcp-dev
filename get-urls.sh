#!/bin/bash

# Get Application URLs Script
# This script shows you all the URLs to access your deployed application

# Color codes
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_ID="app-xyz-dev"
REGION="us-central1"
BACKEND_SERVICE="ecom-backend"
FRONTEND_BUCKET="$PROJECT_ID-frontend"

echo -e "${BLUE}🔗 Your E-commerce Application URLs${NC}"
echo "========================================="

# Frontend URLs
echo -e "\n${GREEN}📱 FRONTEND (React App):${NC}"
echo "Primary URL: https://storage.googleapis.com/$FRONTEND_BUCKET/index.html"
echo "Alternative: https://storage.cloud.google.com/$FRONTEND_BUCKET/index.html"

# Check if frontend files exist
if gsutil ls gs://$FRONTEND_BUCKET/index.html >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Frontend is deployed and accessible${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend not found - may need to deploy${NC}"
fi

# Backend URLs
echo -e "\n${GREEN}🔧 BACKEND API:${NC}"
BACKEND_URL=$(gcloud run services describe $BACKEND_SERVICE --region=$REGION --format='value(status.url)' 2>/dev/null)

if [ ! -z "$BACKEND_URL" ]; then
    echo "API Base URL: $BACKEND_URL"
    echo "Health Check: $BACKEND_URL/health"
    echo "Products API: $BACKEND_URL/api/products"
    echo "Users API: $BACKEND_URL/api/users"
    echo -e "${GREEN}✅ Backend API is deployed and accessible${NC}"
else
    echo -e "${YELLOW}⚠️  Backend not found - may need to deploy${NC}"
fi

# Load Balancer IP (if exists)
echo -e "\n${GREEN}🌐 LOAD BALANCER:${NC}"
LB_IP=$(gcloud compute addresses list --global --format='value(address)' 2>/dev/null | head -1)

if [ ! -z "$LB_IP" ]; then
    echo "Load Balancer IP: http://$LB_IP"
    echo "HTTPS (if SSL configured): https://$LB_IP"
else
    echo -e "${YELLOW}⚠️  No load balancer found${NC}"
fi

# Project Info
echo -e "\n${GREEN}📋 PROJECT INFO:${NC}"
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "Console: https://console.cloud.google.com/home/dashboard?project=$PROJECT_ID"

# Quick Test Commands
echo -e "\n${GREEN}🧪 QUICK TESTS:${NC}"
if [ ! -z "$BACKEND_URL" ]; then
    echo "Test backend: curl $BACKEND_URL/health"
fi
echo "List frontend files: gsutil ls gs://$FRONTEND_BUCKET/"

echo -e "\n${BLUE}💡 TIP: Open the frontend URL in your browser to see your app!${NC}"