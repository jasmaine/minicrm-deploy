#!/bin/bash

# MiniCRM Deployment Script
# Deploys pre-built MiniCRM images using Docker Compose, Kubernetes, or Helm

set -e

# Docker image from GitHub Container Registry
MINICRM_IMAGE="ghcr.io/jasmaine/minicrm:latest"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored message
print_info() {
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

# Print banner
print_banner() {
    echo ""
    echo "======================================"
    echo "   MiniCRM Deployment Script"
    echo "======================================"
    echo ""
    echo "Docker Image: $MINICRM_IMAGE"
    echo ""
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."

    # Check deployment method
    case $DEPLOY_METHOD in
        docker)
            if ! command_exists docker; then
                print_error "Docker is not installed. Please install Docker first."
                exit 1
            fi
            if ! command_exists docker-compose && ! docker compose version >/dev/null 2>&1; then
                print_error "Docker Compose is not installed. Please install Docker Compose first."
                exit 1
            fi
            print_success "Docker and Docker Compose are installed"
            ;;
        kubernetes)
            if ! command_exists kubectl; then
                print_error "kubectl is not installed. Please install kubectl first."
                exit 1
            fi
            print_success "kubectl is installed"
            ;;
        helm)
            if ! command_exists helm; then
                print_error "Helm is not installed. Please install Helm first."
                exit 1
            fi
            if ! command_exists kubectl; then
                print_error "kubectl is not installed. Please install kubectl first."
                exit 1
            fi
            print_success "Helm and kubectl are installed"
            ;;
    esac
}

# Pull latest Docker image
pull_image() {
    print_info "Pulling latest MiniCRM image from GitHub Container Registry..."
    if docker pull $MINICRM_IMAGE; then
        print_success "Image pulled successfully"
    else
        print_error "Failed to pull image. Please check your internet connection."
        exit 1
    fi
}

# Deploy with Docker Compose
deploy_docker() {
    print_info "Deploying MiniCRM with Docker Compose..."

    # Change to docker-compose directory
    if [ ! -d "docker-compose" ]; then
        print_error "docker-compose directory not found. Please run this script from the minicrm-deploy directory."
        exit 1
    fi

    cd docker-compose

    # Check if .env file exists
    if [ ! -f .env ]; then
        print_warning ".env file not found. Creating from .env.example..."
        if [ -f .env.example ]; then
            cp .env.example .env
            print_warning "Please edit .env file with your configuration before continuing."
            echo ""
            echo "Important configuration variables:"
            echo "  - DB_PASSWORD: Database password (change from default!)"
            echo "  - SMTP_* : Email configuration for campaigns"
            echo "  - BASE_URL: Your application URL"
            echo ""
            read -p "Press enter to continue after editing .env file..."
        else
            print_error ".env.example not found. Cannot create .env file."
            exit 1
        fi
    fi

    # Pull latest image
    pull_image

    # Start containers
    print_info "Starting containers..."
    if command_exists docker-compose; then
        docker-compose up -d
    else
        docker compose up -d
    fi

    # Wait for services to be ready
    print_info "Waiting for services to be ready..."
    sleep 10

    # Show status
    print_info "Container status:"
    if command_exists docker-compose; then
        docker-compose ps
    else
        docker compose ps
    fi

    print_success "MiniCRM deployed successfully with Docker Compose!"
    echo ""
    echo "Access MiniCRM at: http://localhost:8080"
    echo "(or the port you configured in .env)"
    echo ""
    echo "Default setup:"
    echo "  - Register the first user to become admin"
    echo "  - Change admin password immediately after first login"
    echo ""
    echo "To view logs:"
    if command_exists docker-compose; then
        echo "  docker-compose logs -f"
    else
        echo "  docker compose logs -f"
    fi
    echo ""
    echo "To stop:"
    if command_exists docker-compose; then
        echo "  docker-compose down"
    else
        echo "  docker compose down"
    fi

    cd ..
}

# Deploy with Kubernetes
deploy_kubernetes() {
    print_info "Deploying MiniCRM to Kubernetes..."

    # Check if k8s directory exists
    if [ ! -d "k8s" ]; then
        print_error "k8s directory not found. Please run this script from the minicrm-deploy directory."
        exit 1
    fi

    # Check if kubectl is connected
    if ! kubectl cluster-info >/dev/null 2>&1; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubectl configuration."
        exit 1
    fi

    print_success "Connected to Kubernetes cluster"

    # Check for namespace
    read -p "Enter namespace (default: minicrm): " K8S_NAMESPACE
    K8S_NAMESPACE=${K8S_NAMESPACE:-minicrm}

    # Check for Ingress Controller
    echo ""
    print_info "Checking for Ingress Controller..."
    if kubectl get deployment -n ingress-nginx ingress-nginx-controller >/dev/null 2>&1; then
        print_success "NGINX Ingress Controller is already installed"
        INGRESS_INSTALLED=true
    else
        print_warning "NGINX Ingress Controller not found"
        read -p "Install NGINX Ingress Controller? [Y/n]: " install_ingress
        if [[ ! $install_ingress =~ ^[Nn]$ ]]; then
            print_info "Installing NGINX Ingress Controller..."
            kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

            print_info "Waiting for Ingress Controller to be ready..."
            kubectl wait --namespace ingress-nginx \
                --for=condition=ready pod \
                --selector=app.kubernetes.io/component=controller \
                --timeout=300s || true

            print_success "NGINX Ingress Controller installed"
            INGRESS_INSTALLED=true
        else
            INGRESS_INSTALLED=false
            print_warning "Skipping Ingress Controller installation. You'll need port-forwarding for access."
        fi
    fi

    # Check for cert-manager (for SSL certificates)
    if [ "$INGRESS_INSTALLED" = true ]; then
        echo ""
        print_info "Checking for cert-manager (SSL certificate automation)..."
        if kubectl get deployment -n cert-manager cert-manager >/dev/null 2>&1; then
            print_success "cert-manager is already installed"
            CERT_MANAGER_INSTALLED=true
        else
            print_warning "cert-manager not found (needed for automatic SSL certificates)"
            read -p "Install cert-manager for automatic SSL certificates? [Y/n]: " install_certmgr
            if [[ ! $install_certmgr =~ ^[Nn]$ ]]; then
                print_info "Installing cert-manager..."
                kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml

                print_info "Waiting for cert-manager to be ready..."
                kubectl wait --namespace cert-manager \
                    --for=condition=ready pod \
                    --selector=app.kubernetes.io/component=controller \
                    --timeout=300s || true

                print_success "cert-manager installed"
                CERT_MANAGER_INSTALLED=true
            else
                CERT_MANAGER_INSTALLED=false
                print_warning "Skipping cert-manager. You'll need to configure SSL manually."
            fi
        fi
    else
        CERT_MANAGER_INSTALLED=false
    fi

    # Update deployment with image name
    print_info "Updating Kubernetes manifests with image: $MINICRM_IMAGE"
    sed -i.bak "s|image:.*minicrm.*|image: $MINICRM_IMAGE|g" k8s/minicrm-deployment.yaml
    rm -f k8s/minicrm-deployment.yaml.bak

    # Ask for domain
    read -p "Enter your domain name (e.g., crm.example.com) or leave empty: " DOMAIN
    if [ -n "$DOMAIN" ]; then
        print_info "Updating Ingress with domain name..."
        sed -i.bak "s|minicrm.example.com|$DOMAIN|g" k8s/ingress.yaml
        rm -f k8s/ingress.yaml.bak
    fi

    # Create namespace
    print_info "Creating namespace: $K8S_NAMESPACE"
    kubectl create namespace $K8S_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

    # Ask about secrets
    echo ""
    print_warning "You need to configure database passwords."
    read -sp "Enter database password: " DB_PASSWORD
    echo ""
    read -sp "Enter PostgreSQL password: " POSTGRES_PASSWORD
    echo ""

    print_info "Creating secrets..."
    kubectl create secret generic minicrm-secrets \
        --from-literal=DB_USER=minicrm \
        --from-literal=DB_PASSWORD=$DB_PASSWORD \
        --from-literal=POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
        -n $K8S_NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -

    # Apply manifests
    print_info "Applying ConfigMap..."
    kubectl apply -f k8s/configmap.yaml -n $K8S_NAMESPACE

    print_info "Creating PersistentVolumeClaims..."
    kubectl apply -f k8s/postgres-pvc.yaml -n $K8S_NAMESPACE
    kubectl apply -f k8s/uploads-pvc.yaml -n $K8S_NAMESPACE

    print_info "Deploying PostgreSQL..."
    kubectl apply -f k8s/postgres-statefulset.yaml -n $K8S_NAMESPACE
    kubectl apply -f k8s/postgres-service.yaml -n $K8S_NAMESPACE

    print_info "Waiting for PostgreSQL to be ready..."
    kubectl wait --for=condition=ready pod -l app=postgres -n $K8S_NAMESPACE --timeout=300s || true

    print_info "Loading database schema..."
    kubectl apply -f k8s/db-schema-job.yaml -n $K8S_NAMESPACE
    kubectl wait --for=condition=complete job/minicrm-db-init -n $K8S_NAMESPACE --timeout=120s || true

    print_info "Deploying MiniCRM application..."
    kubectl apply -f k8s/minicrm-deployment.yaml -n $K8S_NAMESPACE
    kubectl apply -f k8s/minicrm-service.yaml -n $K8S_NAMESPACE

    print_info "Creating Ingress..."
    kubectl apply -f k8s/ingress.yaml -n $K8S_NAMESPACE

    # Setup cert-manager ClusterIssuer if installed
    if [ "$CERT_MANAGER_INSTALLED" = true ] && [ -n "$DOMAIN" ]; then
        echo ""
        read -p "Enter email for Let's Encrypt SSL certificates: " CERT_EMAIL
        if [ -n "$CERT_EMAIL" ]; then
            print_info "Configuring Let's Encrypt certificate issuer..."

            # Update cert-issuer with email
            sed -i.bak "s|email: admin@example.com|email: $CERT_EMAIL|g" k8s/cert-issuer.yaml
            rm -f k8s/cert-issuer.yaml.bak

            # Apply ClusterIssuer
            kubectl apply -f k8s/cert-issuer.yaml

            print_success "SSL certificate automation configured"
            print_info "Certificate will be automatically requested after DNS is configured"
        fi
    fi

    # Optional: HPA
    read -p "Enable auto-scaling (HPA)? [y/N]: " enable_hpa
    if [[ $enable_hpa =~ ^[Yy]$ ]]; then
        print_info "Enabling Horizontal Pod Autoscaler..."
        kubectl apply -f k8s/hpa.yaml -n $K8S_NAMESPACE
    fi

    # Show status
    print_info "Deployment status:"
    kubectl get all -n $K8S_NAMESPACE

    print_success "MiniCRM deployed successfully to Kubernetes!"
    echo ""
    echo "To check status:"
    echo "  kubectl get pods -n $K8S_NAMESPACE"
    echo ""
    echo "To view logs:"
    echo "  kubectl logs -f -l app=minicrm -n $K8S_NAMESPACE"
    echo ""

    if [ -n "$DOMAIN" ] && [ "$INGRESS_INSTALLED" = true ]; then
        echo "Access MiniCRM at: https://$DOMAIN"
        echo ""
        print_info "DNS Configuration Required:"
        echo "Get the Ingress LoadBalancer IP:"
        echo "  kubectl get svc -n ingress-nginx ingress-nginx-controller"
        echo ""
        echo "Then create an A record in your DNS:"
        echo "  $DOMAIN -> <EXTERNAL-IP>"

        if [ "$CERT_MANAGER_INSTALLED" = true ]; then
            echo ""
            print_info "SSL Certificate:"
            echo "After DNS is configured, cert-manager will automatically:"
            echo "  1. Request an SSL certificate from Let's Encrypt"
            echo "  2. Install it on your Ingress"
            echo "  3. Auto-renew it before expiration"
            echo ""
            echo "Check certificate status:"
            echo "  kubectl get certificate -n $K8S_NAMESPACE"
        fi
    else
        print_info "To access MiniCRM locally, run:"
        echo "  kubectl port-forward service/minicrm-service 8000:80 -n $K8S_NAMESPACE"
        echo "  Then open: http://localhost:8000"
    fi
}

# Deploy with Helm
deploy_helm() {
    print_info "Deploying MiniCRM with Helm..."

    # Check if helm-chart directory exists
    if [ ! -d "helm-chart/minicrm" ]; then
        print_error "helm-chart/minicrm directory not found. Please run this script from the minicrm-deploy directory."
        exit 1
    fi

    # Check if kubectl is connected
    if ! kubectl cluster-info >/dev/null 2>&1; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubectl configuration."
        exit 1
    fi

    print_success "Connected to Kubernetes cluster"

    # Ask for release name and namespace
    read -p "Enter Helm release name (default: minicrm): " RELEASE_NAME
    RELEASE_NAME=${RELEASE_NAME:-minicrm}

    read -p "Enter namespace (default: minicrm): " NAMESPACE
    NAMESPACE=${NAMESPACE:-minicrm}

    # Ask if user wants to create custom values file
    echo ""
    echo "Configuration options:"
    echo "1) Use default values"
    echo "2) Create custom values file now"
    read -p "Enter choice [1-2]: " config_choice

    HELM_VALUES_FILE=""

    if [ "$config_choice" = "2" ]; then
        HELM_VALUES_FILE="custom-values.yaml"

        # Collect configuration
        read -p "Enter your domain name (e.g., crm.example.com): " DOMAIN
        read -sp "Enter database password: " DB_PASSWORD
        echo ""
        read -sp "Enter PostgreSQL password: " POSTGRES_PASSWORD
        echo ""

        # Create custom values file
        print_info "Creating custom values file..."
        cat > $HELM_VALUES_FILE <<EOF
image:
  repository: ghcr.io/jasmaine/minicrm
  tag: "latest"

ingress:
  enabled: true
  hosts:
    - host: $DOMAIN
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: minicrm-tls
      hosts:
        - $DOMAIN

minicrm:
  secrets:
    dbPassword: "$DB_PASSWORD"
    postgresPassword: "$POSTGRES_PASSWORD"

postgresql:
  auth:
    password: "$POSTGRES_PASSWORD"
EOF

        print_success "Created $HELM_VALUES_FILE"
    fi

    # Install Helm chart
    print_info "Installing Helm chart..."

    if [ -n "$HELM_VALUES_FILE" ]; then
        helm install $RELEASE_NAME ./helm-chart/minicrm \
            --namespace $NAMESPACE \
            --create-namespace \
            -f $HELM_VALUES_FILE
    else
        helm install $RELEASE_NAME ./helm-chart/minicrm \
            --namespace $NAMESPACE \
            --create-namespace
    fi

    # Wait a bit
    sleep 5

    # Show status
    print_info "Deployment status:"
    helm status $RELEASE_NAME -n $NAMESPACE

    print_success "MiniCRM deployed successfully with Helm!"
    echo ""
    echo "To check status:"
    echo "  helm status $RELEASE_NAME -n $NAMESPACE"
    echo "  kubectl get pods -n $NAMESPACE"
    echo ""
    echo "To view logs:"
    echo "  kubectl logs -f -l app.kubernetes.io/name=minicrm -n $NAMESPACE"
    echo ""
    echo "To upgrade:"
    echo "  helm upgrade $RELEASE_NAME ./helm-chart/minicrm -n $NAMESPACE"
    echo ""
    echo "To uninstall:"
    echo "  helm uninstall $RELEASE_NAME -n $NAMESPACE"
}

# Main menu
show_menu() {
    echo ""
    echo "Select deployment method:"
    echo "1) Docker Compose (recommended for small/medium deployments)"
    echo "2) Kubernetes (kubectl + manifests)"
    echo "3) Helm (Kubernetes package manager)"
    echo "4) Exit"
    echo ""
}

# Main function
main() {
    print_banner

    # Check if running in deployment package
    if [ ! -f "README.md" ]; then
        print_error "README.md not found. Please run this script from the minicrm-deploy directory."
        exit 1
    fi

    # Show menu
    show_menu
    read -p "Enter choice [1-4]: " choice

    case $choice in
        1)
            DEPLOY_METHOD="docker"
            check_prerequisites
            deploy_docker
            ;;
        2)
            DEPLOY_METHOD="kubernetes"
            check_prerequisites
            deploy_kubernetes
            ;;
        3)
            DEPLOY_METHOD="helm"
            check_prerequisites
            deploy_helm
            ;;
        4)
            print_info "Exiting..."
            exit 0
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac

    echo ""
    print_success "Deployment complete!"
    echo ""
    print_info "Next steps:"
    echo "  1. Access the application URL"
    echo "  2. Register the first user (becomes admin)"
    echo "  3. Change admin password immediately"
    echo "  4. Configure SMTP for email campaigns (if not done already)"
}

# Run main function
main
