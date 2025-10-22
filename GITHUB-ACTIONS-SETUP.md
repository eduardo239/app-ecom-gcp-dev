# GitHub Actions Setup Instructions

## 🚨 Current Issue Fix

The error `invalid tag "us-central1-docker.pkg.dev//ecom-app/ecom-backend:dev-..."` occurs because `PROJECT_ID` is empty.

## ✅ **Quick Solutions**

### **Option 1: Use Simple CI Pipeline (Recommended for now)**

The file `.github/workflows/simple-ci.yaml` has been created with:

- ✅ Hard-coded project ID (`app-xyz-dev`)
- ✅ Tests only (no deployment until secrets are configured)
- ✅ Debugging information

### **Option 2: Configure GitHub Secrets**

1. **Go to your GitHub repository**
2. **Settings** → **Secrets and variables** → **Actions**
3. **Add repository secrets:**

| Secret Name      | Value          | Description                  |
| ---------------- | -------------- | ---------------------------- |
| `GCP_PROJECT_ID` | `app-xyz-dev`  | Your Google Cloud project ID |
| `GCP_SA_KEY`     | `{...json...}` | Service account JSON key     |

### **Option 3: Manual Local Deployment**

Since GitHub Actions is having issues, deploy manually:

```bash
# Set your project ID
export PROJECT_ID="app-xyz-dev"

# Build and push backend manually
cd backend
docker build -t us-central1-docker.pkg.dev/$PROJECT_ID/ecom-app/ecom-backend:latest .

# Configure Docker for Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev

# Push the image
docker push us-central1-docker.pkg.dev/$PROJECT_ID/ecom-app/ecom-backend:latest

# Deploy to Cloud Run
gcloud run deploy ecom-backend-dev \
    --image us-central1-docker.pkg.dev/$PROJECT_ID/ecom-app/ecom-backend:latest \
    --region us-central1 \
    --allow-unauthenticated \
    --set-env-vars FLASK_ENV=development

# Build and deploy frontend
cd ../frontend
npm ci
npm run build
gsutil -m rsync -r -d dist gs://$PROJECT_ID-frontend-dev
gsutil -m acl ch -r -u AllUsers:R gs://$PROJECT_ID-frontend-dev
```

## 🔧 **Creating Service Account for GitHub Actions**

If you want to use GitHub Actions with proper authentication:

```bash
# Create service account
gcloud iam service-accounts create github-actions \
    --description="GitHub Actions deployment" \
    --display-name="GitHub Actions"

# Grant necessary roles
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/run.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.writer"

# Create and download key
gcloud iam service-accounts keys create github-actions-key.json \
    --iam-account=github-actions@$PROJECT_ID.iam.gserviceaccount.com

# Copy the contents of github-actions-key.json to GitHub secret GCP_SA_KEY
cat github-actions-key.json
```

## 📋 **Current Status**

- ❌ **GitHub Actions deployment**: Disabled due to missing secrets
- ✅ **GitHub Actions testing**: Working in `simple-ci.yaml`
- ✅ **Manual deployment**: Available via commands above
- ⚠️ **Cloud Build triggers**: Need repository connection (separate issue)

## 🎯 **Recommended Next Steps**

1. **Use simple CI for now**: Push code to test the `simple-ci.yaml` workflow
2. **Deploy manually**: Use the commands above for deployment
3. **Configure secrets later**: When ready for automated deployment
4. **Fix Cloud Build**: Separately address the trigger creation issues

## 🚀 **Test the Simple CI**

Push code to any branch and check:

- GitHub Actions tab in your repository
- Should see "Simple CI/CD Pipeline" running
- Will show configuration debug info and run tests
