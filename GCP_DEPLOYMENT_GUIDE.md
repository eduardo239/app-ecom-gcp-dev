# Google Cloud Platform Deployment Guide

## Architecture Overview

```
Internet -> Cloud Load Balancer -> Cloud CDN -> Cloud Storage (React Frontend)
                                            -> Cloud Run (Flask Backend) -> Cloud SQL (Database)
```

## Required GCP Services

### 1. Frontend Deployment

- **Cloud Storage**: Host React build files
- **Cloud CDN**: Global content delivery
- **Cloud Load Balancer**: Route traffic and SSL termination

### 2. Backend Deployment

- **Cloud Run**: Serverless Flask API hosting
- **Cloud Build**: CI/CD for containerization
- **Artifact Registry**: Container image storage

### 3. Database

- **Cloud SQL**: Managed PostgreSQL/MySQL database
- **Cloud SQL Proxy**: Secure database connections

### 4. Additional Services

- **Identity and Access Management (IAM)**: Security and permissions
- **Cloud Monitoring**: Application monitoring and logging
- **Cloud DNS**: Custom domain management (optional)

## Cost Estimation (Monthly)

### Basic Setup (~$15-30/month)

- Cloud Storage: $1-3
- Cloud CDN: $1-5
- Cloud Run: $5-15 (depending on traffic)
- Cloud SQL: $7-25 (db-f1-micro to db-n1-standard-1)
- Load Balancer: $18/month (if using Global Load Balancer)

### Production Setup (~$50-200/month)

- Enhanced monitoring and logging
- Higher-tier database instances
- Multiple environments (dev/staging/prod)
- Advanced security features

## Step-by-Step Deployment

### Prerequisites

1. GCP Account with billing enabled
2. `gcloud` CLI installed and configured
3. Docker installed (for backend containerization)

### Backend Deployment (Cloud Run)

1. **Create Dockerfile for Flask app**
2. **Build and push to Artifact Registry**
3. **Deploy to Cloud Run**
4. **Configure environment variables**

### Frontend Deployment (Cloud Storage + CDN)

1. **Build React app for production**
2. **Upload to Cloud Storage bucket**
3. **Configure bucket for web hosting**
4. **Set up Cloud CDN**
5. **Configure Load Balancer**

### Database Setup (Cloud SQL)

1. **Create Cloud SQL instance**
2. **Configure database and users**
3. **Set up connection from Cloud Run**
4. **Migrate data/schema**

## Security Considerations

- Enable HTTPS/SSL certificates
- Configure CORS properly
- Use Cloud IAM for service authentication
- Enable Cloud SQL private IP
- Set up VPC for network isolation
- Enable Cloud Armor for DDoS protection

## Monitoring and Logging

- Cloud Monitoring for metrics
- Cloud Logging for application logs
- Error Reporting for error tracking
- Cloud Trace for request tracing

## CI/CD Pipeline

- Cloud Build for automated deployments
- Cloud Source Repositories for code hosting
- Automated testing and deployment triggers

## Scaling Considerations

- Cloud Run auto-scales based on traffic
- Cloud SQL read replicas for database scaling
- Cloud CDN for global content delivery
- Multi-region deployment for high availability
