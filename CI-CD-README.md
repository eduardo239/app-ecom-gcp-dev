# CI/CD Pipeline Documentation

This project uses Google Cloud Build for automated CI/CD deployments with multiple environment support.

## Pipeline Overview

### 🏗️ Build Configurations

1. **`cloudbuild.yaml`** - Main staging/manual deployment pipeline
2. **`cloudbuild-dev.yaml`** - Development environment (auto-deploy on dev branches)
3. **`cloudbuild-prod.yaml`** - Production environment (auto-deploy on main branch)
4. **`.github/workflows/ci-cd.yaml`** - Alternative GitHub Actions pipeline

### 🚀 Deployment Environments

| Environment | Trigger   | Branch/Tag                    | Config File            |
| ----------- | --------- | ----------------------------- | ---------------------- |
| Development | Automatic | `develop`, `dev`, `feature/*` | `cloudbuild-dev.yaml`  |
| Staging     | Manual    | Any branch                    | `cloudbuild.yaml`      |
| Production  | Automatic | `main`, `master`              | `cloudbuild-prod.yaml` |

## 🛠️ Setup Instructions

### 1. Prerequisites

- Google Cloud Project with billing enabled
- GitHub repository connected to Cloud Build
- Required APIs enabled (done by setup script)

### 2. Initial Setup

Run the automated setup script:

```bash
# Make executable
chmod +x setup-cicd.sh

# Run setup (replace with your project ID)
./setup-cicd.sh YOUR_PROJECT_ID
```

Or manually:

```bash
# Enable APIs
gcloud services enable cloudbuild.googleapis.com run.googleapis.com artifactregistry.googleapis.com

# Create Artifact Registry
gcloud artifacts repositories create ecom-app --repository-format=docker --location=us-central1

# Set up IAM permissions (see setup-cicd.sh for details)
```

### 3. Configure Secrets

Create required secrets in Google Secret Manager:

```bash
# Database URL (update with actual values)
echo "postgresql://user:password@host:5432/database" | \
    gcloud secrets create database-url --data-file=-
```

### 4. GitHub Integration

1. Go to [Cloud Build Triggers](https://console.cloud.google.com/cloud-build/triggers)
2. Connect your GitHub repository
3. Triggers will be automatically created by the setup script

## 🔄 Pipeline Stages

### Development Pipeline (`cloudbuild-dev.yaml`)

```mermaid
graph LR
    A[Code Push] --> B[Run Tests]
    B --> C[Build Images]
    C --> D[Deploy to Dev]
    D --> E[Smoke Tests]
```

**Stages:**

1. **Test** - Backend (pytest) and Frontend (ESLint, TypeScript)
2. **Build** - Docker image and static assets
3. **Deploy** - Cloud Run (dev) and Cloud Storage (dev)
4. **Verify** - Basic health checks

### Production Pipeline (`cloudbuild-prod.yaml`)

```mermaid
graph LR
    A[Main Branch] --> B[Security Scan]
    B --> C[Build & Test]
    C --> D[Deploy w/o Traffic]
    D --> E[Smoke Tests]
    E --> F[Route Traffic]
    F --> G[Frontend Deploy]
```

**Stages:**

1. **Security** - Bandit, Safety, comprehensive testing
2. **Build** - Optimized production builds
3. **Deploy** - Zero-downtime deployment with traffic management
4. **Test** - Smoke tests on new revision
5. **Release** - Route traffic to new version
6. **Frontend** - Deploy with cache optimization

## 🎯 Manual Deployments

### Trigger Individual Builds

```bash
# Development
gcloud builds submit --config cloudbuild-dev.yaml

# Production
gcloud builds submit --config cloudbuild-prod.yaml

# Staging with custom environment
gcloud builds submit --config cloudbuild.yaml \
    --substitutions=_ENVIRONMENT=staging
```

### Deploy Specific Component

```bash
# Backend only
gcloud builds submit --config backend/cloudbuild.yaml

# Frontend only (manual)
cd frontend && npm run build
gsutil -m rsync -r -d dist gs://YOUR_PROJECT_ID-frontend-dev
```

## 📊 Monitoring & Logs

### Build History

- [Cloud Build Console](https://console.cloud.google.com/cloud-build/builds)
- View logs, timing, and build artifacts

### Application Monitoring

- **Backend**: Cloud Run logs and metrics
- **Frontend**: Cloud Storage access logs
- **Database**: Cloud SQL monitoring (if used)

### Useful Commands

```bash
# View recent builds
gcloud builds list --limit=10

# Get build logs
gcloud builds log BUILD_ID

# Check Cloud Run services
gcloud run services list

# Check frontend deployments
gsutil ls gs://YOUR_PROJECT_ID-frontend-*
```

## 🔧 Troubleshooting

### Common Issues

1. **Permission Denied**

   ```bash
   # Check Cloud Build service account permissions
   gcloud projects get-iam-policy PROJECT_ID
   ```

2. **Build Timeout**

   - Increase timeout in build config
   - Optimize Docker build layers
   - Use multi-stage builds

3. **Test Failures**

   ```bash
   # Run tests locally
   cd backend && python -m pytest tests/
   cd frontend && npm test
   ```

4. **Deployment Issues**
   ```bash
   # Check Cloud Run logs
   gcloud logs read --service=ecom-backend-prod --limit=50
   ```

### Environment Variables

Required substitutions in build configs:

- `_REGION` - Deployment region (default: us-central1)
- `_ENVIRONMENT` - Environment name (dev/staging/prod)
- `_ARTIFACT_REGISTRY_REPO` - Registry repo name (default: ecom-app)

## 🚀 Advanced Features

### Blue-Green Deployments

Production pipeline includes:

- Deploy new revision without traffic
- Run smoke tests
- Gradually route traffic to new version
- Automatic rollback on failure

### Multi-Environment Support

Each environment has:

- Separate Cloud Run services
- Separate Storage buckets
- Environment-specific configurations
- Independent scaling settings

### Security Features

- Container vulnerability scanning
- Dependency vulnerability checks (Safety, Bandit)
- Secret management with Secret Manager
- Least-privilege IAM roles

## 📝 Customization

### Adding New Environments

1. Create new build config file
2. Add trigger in `setup-cicd.sh`
3. Update substitutions for environment-specific values

### Adding Tests

Backend tests in `backend/tests/`:

```python
def test_new_feature(client):
    response = client.get('/api/new-endpoint')
    assert response.status_code == 200
```

Frontend tests (when Vitest is installed):

```typescript
import { render } from '@testing-library/react';
import { App } from './App';

test('renders app', () => {
  render(<App />);
});
```

### Custom Build Steps

Add to any `cloudbuild.yaml`:

```yaml
- name: 'custom-builder'
  args: ['custom', 'command']
  env: ['CUSTOM_VAR=value']
```

## 🔗 Useful Links

- [Cloud Build Documentation](https://cloud.google.com/build/docs)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Artifact Registry Documentation](https://cloud.google.com/artifact-registry/docs)
- [Secret Manager Documentation](https://cloud.google.com/secret-manager/docs)
