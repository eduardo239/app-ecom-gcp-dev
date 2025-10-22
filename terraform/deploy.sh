#!/bin/bash

# Terraform Deployment Script for GCP E-commerce App
# This script helps deploy the infrastructure using Terraform

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    if ! command -v gcloud &> /dev/null; then
        print_error "Google Cloud SDK is not installed. Please install gcloud CLI first."
        exit 1
    fi
    
    # Check if user is authenticated with gcloud
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "You are not authenticated with gcloud. Please run 'gcloud auth login' first."
        exit 1
    fi
    
    print_success "Prerequisites check passed!"
}

# Initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    
    cd terraform
    
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Please copy terraform.tfvars.example to terraform.tfvars and customize it."
        print_status "Copying example file..."
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Please edit terraform.tfvars with your project-specific values before continuing."
        exit 1
    fi
    
    terraform init
    print_success "Terraform initialized!"
}

# Plan Terraform deployment
plan_terraform() {
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
    print_success "Terraform plan created!"
}

# Apply Terraform deployment
apply_terraform() {
    print_status "Applying Terraform deployment..."
    
    # Ask for confirmation
    read -p "Do you want to apply these changes? (yes/no): " confirmation
    if [[ $confirmation != "yes" ]]; then
        print_warning "Deployment cancelled by user."
        exit 0
    fi
    
    terraform apply tfplan
    print_success "Infrastructure deployed successfully!"
}

# Get outputs
show_outputs() {
    print_status "Deployment Information:"
    echo "========================"
    terraform output
    echo ""
    
    print_status "Important URLs:"
    terraform output -json application_urls | jq -r 'to_entries[] | "\(.key): \(.value // "Not configured")"'
    echo ""
    
    print_status "Next Steps:"
    echo "1. Build and deploy your backend container image:"
    echo "   cd ../backend"
    echo "   gcloud builds submit --tag gcr.io/$(terraform output -raw project_id)/$(terraform output -raw backend_service_name)"
    echo ""
    echo "2. Update the Cloud Run service with your image:"
    echo "   gcloud run deploy $(terraform output -raw backend_service_name) \\"
    echo "     --image gcr.io/$(terraform output -raw project_id)/$(terraform output -raw backend_service_name) \\"
    echo "     --region $(terraform output -raw region)"
    echo ""
    echo "3. Build and deploy your frontend:"
    echo "   cd ../frontend"
    echo "   npm run build"
    echo "   gsutil -m rsync -r -d dist/ gs://$(terraform output -raw frontend_bucket_name)/"
    echo ""
    
    if terraform output domain_name &> /dev/null; then
        print_status "4. Configure DNS for your custom domain:"
        echo "   Point your domain to: $(terraform output -raw load_balancer_ip)"
    fi
}

# Destroy infrastructure
destroy_terraform() {
    print_warning "This will destroy ALL infrastructure resources!"
    read -p "Are you sure you want to destroy the infrastructure? Type 'destroy' to confirm: " confirmation
    
    if [[ $confirmation != "destroy" ]]; then
        print_warning "Destroy cancelled by user."
        exit 0
    fi
    
    print_status "Destroying infrastructure..."
    terraform destroy -auto-approve
    print_success "Infrastructure destroyed!"
}

# Main menu
show_menu() {
    echo ""
    echo "GCP E-commerce Infrastructure Deployment"
    echo "========================================"
    echo "1. Initialize Terraform"
    echo "2. Plan deployment"
    echo "3. Apply deployment"
    echo "4. Show outputs"
    echo "5. Destroy infrastructure"
    echo "6. Exit"
    echo ""
}

# Main script logic
main() {
    check_prerequisites
    
    while true; do
        show_menu
        read -p "Choose an option (1-6): " choice
        
        case $choice in
            1)
                init_terraform
                ;;
            2)
                plan_terraform
                ;;
            3)
                apply_terraform
                show_outputs
                ;;
            4)
                show_outputs
                ;;
            5)
                destroy_terraform
                ;;
            6)
                print_status "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please choose 1-6."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run the main function
main