#!/bin/bash
set -e

# YO3 Platform - Production Deployment Script (Linux/Mac)
# CaCTUs Zero-Trust Surveillance System

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

cat << "EOF"
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║   YO3 Platform - Zero-Trust Surveillance System                ║
║   Deployment Script v1.0.0                                     ║
║   CaCTUs Architecture                                          ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
EOF

# Parse arguments
LOAD_IMAGES=false
DEPLOY=false
VERIFY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --load-images) LOAD_IMAGES=true; shift ;;
        --deploy) DEPLOY=true; shift ;;
        --verify) VERIFY=true; shift ;;
        --all) LOAD_IMAGES=true; DEPLOY=true; VERIFY=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Default to all if no options
if [ "$LOAD_IMAGES" = false ] && [ "$DEPLOY" = false ] && [ "$VERIFY" = false ]; then
    LOAD_IMAGES=true
    DEPLOY=true
    VERIFY=true
fi

# Prerequisites Check
info "Checking prerequisites..."

# Check Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "unknown")
    success "Docker Engine $DOCKER_VERSION detected"
else
    error "Docker is not installed"
    info "Install from: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check docker-compose
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose version --short 2>/dev/null || echo "unknown")
    success "Docker Compose $COMPOSE_VERSION detected"
else
    error "Docker Compose is not installed"
    exit 1
fi

# Check .env file
if [ ! -f ".env" ]; then
    warning ".env file not found"
    if [ -f ".env.example" ]; then
        info "Copying .env.example to .env..."
        cp .env.example .env
        warning "CRITICAL: Edit .env with production secrets before deploying!"
        echo ""
        echo -e "${YELLOW}Required changes:${NC}"
        echo -e "${YELLOW}  - JWT_SECRET (min 32 chars)${NC}"
        echo -e "${YELLOW}  - DB_PASSWORD${NC}"
        echo -e "${YELLOW}  - YO3_MASTER_KEY${NC}"
        echo -e "${YELLOW}  - DEVICE_TOKEN${NC}"
        echo ""
        read -p "Continue deployment? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Deployment cancelled"
            exit 0
        fi
    else
        error ".env.example not found. Cannot proceed."
        exit 1
    fi
else
    success ".env file found"
fi

# Load Docker Images
if [ "$LOAD_IMAGES" = true ]; then
    info "Loading Docker images..."
    IMAGE_DIR="./images"
    
    if [ -d "$IMAGE_DIR" ]; then
        TAR_FILES=$(find "$IMAGE_DIR" -name "*.tar" 2>/dev/null)
        if [ -z "$TAR_FILES" ]; then
            warning "No .tar files found in $IMAGE_DIR"
        else
            for tar_file in $TAR_FILES; do
                info "Loading $(basename $tar_file)..."
                if docker load -i "$tar_file"; then
                    success "Loaded $(basename $tar_file)"
                else
                    error "Failed to load $(basename $tar_file)"
                fi
            done
        fi
    else
        warning "Images directory not found. Skipping image load."
        info "If images are not in registry, build them with: docker-compose build"
    fi
fi

# Deploy Containers
if [ "$DEPLOY" = true ]; then
    info "Deploying YO3 Platform containers..."
    
    # Stop existing containers
    info "Stopping existing containers..."
    docker-compose down 2>/dev/null || true
    
    # Pull/build images if needed
    info "Ensuring images are ready..."
    docker-compose pull 2>/dev/null || true
    
    # Start services
    info "Starting services..."
    if docker-compose up -d; then
        success "Containers deployed successfully"
    else
        error "Container deployment failed"
        info "Check logs with: docker-compose logs"
        exit 1
    fi
    
    info "Waiting for services to initialize (30s)..."
    sleep 30
fi

# Verify Deployment
if [ "$VERIFY" = true ]; then
    info "Verifying deployment health..."
    
    # Check container status
    info "Container status:"
    docker-compose ps
    
    # Health check endpoints
    declare -A HEALTH_CHECKS=(
        ["Identity Service"]="http://localhost:8081/api/health"
        ["Data-Core (Microkernel)"]="http://localhost:9090/api/health"
        ["Stream Processing"]="http://localhost:8082/api/health"
        ["Middleware"]="http://localhost:8091/api/health"
    )
    
    echo ""
    info "Health check results:"
    ALL_HEALTHY=true
    
    for service in "${!HEALTH_CHECKS[@]}"; do
        url="${HEALTH_CHECKS[$service]}"
        if curl -sf "$url" > /dev/null 2>&1; then
            success "$service: Healthy"
        else
            error "$service: Unreachable"
            ALL_HEALTHY=false
        fi
    done
    
    echo ""
    if [ "$ALL_HEALTHY" = true ]; then
        success "All services are healthy!"
        echo ""
        echo -e "${CYAN}Access Points:${NC}"
        echo -e "  Frontend:      http://localhost:5173"
        echo -e "  Identity API:  http://localhost:8081"
        echo -e "  Data-Core API: http://localhost:9090"
        echo -e "  Stream API:    http://localhost:8082"
        echo -e "  Middleware:    http://localhost:8091"
        echo ""
        echo -e "${CYAN}Useful Commands:${NC}"
        echo -e "  View logs:     docker-compose logs -f"
        echo -e "  Stop services: docker-compose down"
        echo -e "  Restart:       docker-compose restart"
    else
        warning "Some services are not healthy. Check logs:"
        echo -e "  ${YELLOW}docker-compose logs -f${NC}"
    fi
fi

echo ""
success "Deployment script completed"
