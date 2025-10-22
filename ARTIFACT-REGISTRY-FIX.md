# Artifact Registry Permission Fix Guide

## 🚨 **Current Issue**

```
denied: Permission "artifactregistry.repositories.uploadArtifacts" denied on resource
"projects/app-xyz-dev/locations/us-central1/repositories/ecom-app" (or it may not exist)
```

## 🔍 **Root Causes**

1. The Artifact Registry repository `ecom-app` doesn't exist
2. The Artifact Registry API is not enabled
3. Your user account lacks necessary permissions
4. Docker authentication is not configured

## ✅ **Step-by-Step Fix**

### **1. Enable Artifact Registry API**

```bash
gcloud services enable artifactregistry.googleapis.com --project=app-xyz-dev
```

### **2. Create the Artifact Registry Repository**

```bash
gcloud artifacts repositories create ecom-app \
    --repository-format=docker \
    --location=us-central1 \
    --description="E-commerce app container images" \
    --project=app-xyz-dev
```

### **3. Verify Repository Creation**

```bash
gcloud artifacts repositories list --location=us-central1 --project=app-xyz-dev
```

### **4. Configure Docker Authentication**

```bash
gcloud auth configure-docker us-central1-docker.pkg.dev
```

### **5. Grant Permissions to Your User (if needed)**

```bash
# Get your current user email
CURRENT_USER=$(gcloud config get-value account)
echo "Current user: $CURRENT_USER"

# Grant necessary roles
gcloud projects add-iam-policy-binding app-xyz-dev \
    --member="user:$CURRENT_USER" \
    --role="roles/artifactregistry.admin"
```

### **6. Test the Setup**

```bash
# Test Docker authentication
docker pull alpine:latest
docker tag alpine:latest us-central1-docker.pkg.dev/app-xyz-dev/ecom-app/test:latest
docker push us-central1-docker.pkg.dev/app-xyz-dev/ecom-app/test:latest

# If successful, clean up the test image
gcloud artifacts docker images delete us-central1-docker.pkg.dev/app-xyz-dev/ecom-app/test:latest --quiet
```

## 🚀 **Alternative: Use Existing Container Registry (GCR)**

If Artifact Registry continues to have issues, you can temporarily use the older Google Container Registry:

### **Update your build configurations:**

**For GitHub Actions:**

```yaml
# Replace this:
# $REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REGISTRY_REPO/ecom-backend:dev-${{ github.sha }}

# With this:
# gcr.io/$PROJECT_ID/ecom-backend:dev-${{ github.sha }}
```

**For Cloud Build:**

```yaml
# In your cloudbuild-dev.yaml, replace:
args:
  - 'build'
  - '-t'
  - 'gcr.io/$PROJECT_ID/ecom-backend:dev-$BUILD_ID'
  - '.'
```

### **Configure Docker for GCR:**

```bash
gcloud auth configure-docker gcr.io
```

### **Enable Container Registry API:**

```bash
gcloud services enable containerregistry.googleapis.com --project=app-xyz-dev
```

## 🔧 **Quick One-Command Fix**

Run this single command to set up everything:

```bash
# Enable APIs, create repository, configure Docker
gcloud services enable artifactregistry.googleapis.com containerregistry.googleapis.com --project=app-xyz-dev && \
gcloud artifacts repositories create ecom-app --repository-format=docker --location=us-central1 --project=app-xyz-dev && \
gcloud auth configure-docker us-central1-docker.pkg.dev && \
echo "✅ Artifact Registry setup completed!"
```

## 🧪 **Verification Commands**

Check if everything is working:

```bash
# 1. Check enabled APIs
gcloud services list --enabled --filter="name:(artifactregistry.googleapis.com OR containerregistry.googleapis.com)" --project=app-xyz-dev

# 2. List repositories
gcloud artifacts repositories list --project=app-xyz-dev

# 3. Check Docker authentication
docker system info | grep -i "Registry:"

# 4. Test push (using a simple image)
docker pull hello-world
docker tag hello-world us-central1-docker.pkg.dev/app-xyz-dev/ecom-app/hello-world:test
docker push us-central1-docker.pkg.dev/app-xyz-dev/ecom-app/hello-world:test
```

## 📋 **Common Issues and Solutions**

| Issue                          | Solution                                                      |
| ------------------------------ | ------------------------------------------------------------- |
| "API not enabled"              | `gcloud services enable artifactregistry.googleapis.com`      |
| "Repository does not exist"    | Create with `gcloud artifacts repositories create`            |
| "Permission denied"            | Grant `roles/artifactregistry.admin` to your user             |
| "Docker authentication failed" | Run `gcloud auth configure-docker us-central1-docker.pkg.dev` |
| "Invalid project"              | Verify project ID with `gcloud config get-value project`      |

## 🎯 **Next Steps After Fix**

1. **Test the backend build:**

   ```bash
   cd backend
   docker build -t us-central1-docker.pkg.dev/app-xyz-dev/ecom-app/ecom-backend:latest .
   docker push us-central1-docker.pkg.dev/app-xyz-dev/ecom-app/ecom-backend:latest
   ```

2. **Deploy to Cloud Run:**

   ```bash
   gcloud run deploy ecom-backend-dev \
       --image us-central1-docker.pkg.dev/app-xyz-dev/ecom-app/ecom-backend:latest \
       --region us-central1 \
       --allow-unauthenticated \
       --project=app-xyz-dev
   ```

3. **Test GitHub Actions:** Push code to trigger the workflow

The most likely solution is running the one-command fix above! 🚀
