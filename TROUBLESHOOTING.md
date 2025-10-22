# Cloud Build Triggers Troubleshooting Guide

The `INVALID_ARGUMENT` error when creating Cloud Build triggers typically occurs due to one of these common issues:

## 🔍 **Most Common Causes**

### 1. **GitHub Repository Not Connected**
The most frequent cause is that your GitHub repository isn't connected to Cloud Build.

**Solution:**
```bash
# Check if GitHub app is connected
gcloud source repos list

# If empty, connect your repository:
# 1. Go to: https://console.cloud.google.com/cloud-build/triggers/connect
# 2. Select "GitHub (Cloud Build GitHub App)"
# 3. Authenticate and select your repository
```

### 2. **Trigger Names Already Exist**
Triggers with the same name may already exist.

**Solution:**
```bash
# List existing triggers
gcloud builds triggers list

# Delete existing triggers if needed
gcloud builds triggers delete ecom-app-dev
gcloud builds triggers delete ecom-app-prod  
gcloud builds triggers delete ecom-app-staging
```

### 3. **Invalid Repository Configuration**
Repository owner/name mismatch or repository access issues.

**Solution:**
```bash
# Verify repository details
./debug-cicd.sh YOUR_PROJECT_ID

# Use correct repository owner and name
./setup-cicd.sh YOUR_PROJECT_ID eduardo239 app-ecom-gcp-dev
```

## 🛠️ **Quick Fix Options**

### **Option 1: Use the Debug Script**
```bash
chmod +x debug-cicd.sh
./debug-cicd.sh YOUR_PROJECT_ID
```
This will diagnose the exact issue and provide specific solutions.

### **Option 2: Use JSON Import Method**
```bash
chmod +x create-triggers.sh
./create-triggers.sh YOUR_PROJECT_ID
```
This uses a different API method that often works when the standard approach fails.

### **Option 3: Manual Console Creation**
1. Go to [Cloud Build Triggers](https://console.cloud.google.com/cloud-build/triggers)
2. Click "Create Trigger"
3. Use these settings:

**Development Trigger:**
- Name: `ecom-app-dev`
- Repository: `eduardo239/app-ecom-gcp-dev`
- Branch pattern: `^(develop|dev|feature/.*)$`
- Build configuration: `cloudbuild-dev.yaml`

**Production Trigger:**
- Name: `ecom-app-prod`
- Repository: `eduardo239/app-ecom-gcp-dev`
- Branch pattern: `^(main|master)$`
- Build configuration: `cloudbuild-prod.yaml`

**Staging Trigger:**
- Name: `ecom-app-staging`
- Repository: `eduardo239/app-ecom-gcp-dev`
- Tag pattern: `v.*`
- Build configuration: `cloudbuild.yaml`
- Substitution variables: `_ENVIRONMENT = staging`

## 🔧 **Alternative Solutions**

### **Manual Build Submission**
If triggers continue to fail, you can manually trigger builds:

```bash
# Manual development build
gcloud builds submit --config cloudbuild-dev.yaml

# Manual production build  
gcloud builds submit --config cloudbuild-prod.yaml

# Manual staging build with substitutions
gcloud builds submit --config cloudbuild.yaml --substitutions=_ENVIRONMENT=staging
```

### **GitHub Actions Alternative**
Use the GitHub Actions workflow instead of Cloud Build triggers:

1. Set up GitHub secrets:
   - `GCP_PROJECT_ID`: Your Google Cloud project ID
   - `GCP_SA_KEY`: Service account JSON key

2. The workflow in `.github/workflows/ci-cd.yaml` will handle CI/CD automatically

### **Using Cloud Source Repositories**
If GitHub integration continues to fail, mirror your repository to Cloud Source Repositories:

```bash
# Create Cloud Source Repository
gcloud source repos create app-ecom-gcp-dev

# Add as remote
git remote add google https://source.developers.google.com/p/YOUR_PROJECT_ID/r/app-ecom-gcp-dev

# Push to Cloud Source Repositories
git push google main

# Create triggers for Cloud Source Repositories
gcloud builds triggers create cloud-source-repositories \
    --repo=app-ecom-gcp-dev \
    --branch-pattern="^main$" \
    --build-config=cloudbuild-prod.yaml \
    --name="ecom-app-prod-csr"
```

## 📋 **Verification Steps**

After creating triggers, verify they work:

```bash
# List all triggers
gcloud builds triggers list

# Test trigger manually
gcloud builds triggers run ecom-app-dev --branch=develop

# Check build history
gcloud builds list --limit=5
```

## 🚨 **Common Error Messages and Solutions**

| Error | Cause | Solution |
|-------|-------|----------|
| `INVALID_ARGUMENT` | Repository not connected | Connect GitHub app |
| `ALREADY_EXISTS` | Trigger name conflict | Delete existing or use different name |
| `PERMISSION_DENIED` | Missing IAM permissions | Run permission setup in script |
| `NOT_FOUND` | Build config file missing | Ensure YAML files exist in repo |

## 📞 **Need Help?**

Run the diagnostic script for detailed troubleshooting:
```bash
./debug-cicd.sh YOUR_PROJECT_ID
```

This will check:
- ✅ API enablement
- ✅ GitHub connections  
- ✅ IAM permissions
- ✅ Build configuration files
- ✅ Existing triggers