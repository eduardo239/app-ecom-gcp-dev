# 🗑️ Resource Cleanup Guide

## How to Destroy All Resources

### Method 1: Using Terraform (If you used Terraform)

```bash
cd terraform
./deploy.sh
# Choose option 5: "Destroy infrastructure"
```

Or manually:

```bash
cd terraform
terraform destroy
```

### Method 2: Using the Cleanup Script (For manual deployments)

```bash
# Make sure to edit the PROJECT_ID in cleanup.sh first
./cleanup.sh
```

### Method 3: Manual Cleanup via gcloud CLI

#### Quick Commands:

```bash
# Set your project
gcloud config set project YOUR_PROJECT_ID

# Delete Cloud Run services
gcloud run services delete ecom-backend --region=us-central1

# Delete Cloud SQL instance (⚠️ DELETES ALL DATA!)
gcloud sql instances delete ecom-db

# Delete Storage buckets (⚠️ DELETES ALL FILES!)
gsutil rm -r gs://your-project-frontend
gsutil rm -r gs://your-project-assets

# Delete Artifact Registry
gcloud artifacts repositories delete ecom-backend --location=us-central1
```

### Method 4: Using GCP Console (Web Interface)

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Navigate to each service:
   - **Cloud Run**: Delete services
   - **Cloud SQL**: Delete instances
   - **Cloud Storage**: Delete buckets
   - **Artifact Registry**: Delete repositories
   - **Load Balancing**: Delete load balancers
   - **VPC Network**: Delete networks and subnets
   - **IAM**: Delete service accounts

## ⚠️ Important Warnings

- **Database deletion is PERMANENT** - all data will be lost
- **Storage bucket deletion is PERMANENT** - all files will be lost
- **Some resources may have dependencies** - delete in the right order
- **Check billing** after deletion to ensure you're not charged

## 💰 Stop All Billing

To ensure you don't get charged for any remaining resources:

1. **Delete the entire project** (nuclear option):

   ```bash
   gcloud projects delete YOUR_PROJECT_ID
   ```

2. **Or check for remaining resources**:
   ```bash
   gcloud asset search-all-resources --project=YOUR_PROJECT_ID
   ```

## 🔍 Verify Cleanup

After deletion, verify everything is gone:

```bash
# Check Cloud Run
gcloud run services list --region=us-central1

# Check Cloud SQL
gcloud sql instances list

# Check Storage
gsutil ls

# Check Artifact Registry
gcloud artifacts repositories list --location=us-central1
```

## 📋 Cleanup Checklist

- [ ] Cloud Run services deleted
- [ ] Cloud SQL instances deleted
- [ ] Storage buckets deleted
- [ ] Artifact Registry repositories deleted
- [ ] Load balancers deleted
- [ ] VPC networks deleted
- [ ] Service accounts deleted
- [ ] Secrets deleted
- [ ] Custom IAM roles deleted
- [ ] DNS records updated (if using custom domain)
- [ ] Billing verified to be stopped
