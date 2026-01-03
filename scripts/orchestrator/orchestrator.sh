#!/bin/bash
################################################################################
# YO3 Platform - Service Orchestrator
# ============================================================
# Manages startup, health, and lifecycle of all platform services
# within a single container
################################################################################

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# PID tracking for cleanup
declare -a PIDS
declare -a SERVICES

# Cleanup function - ensures all services are stopped gracefully
cleanup() {
    log_warn "Shutting down YO3 Platform gracefully..."
    
    # Send SIGTERM to all running processes
    for pid in "${PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            log "Terminating process $pid..."
            kill -TERM "$pid" 2>/dev/null || true
        fi
    done
    
    # Wait for graceful shutdown (max 30 seconds)
    sleep 5
    
    # Force kill any remaining processes
    for pid in "${PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            log_error "Force killing process $pid..."
            kill -KILL "$pid" 2>/dev/null || true
        fi
    done
    
    log_success "YO3 Platform shutdown complete"
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

################################################################################
# Environment Configuration
################################################################################

log "Configuring YO3 Platform environment..."

# Set defaults if not provided
export SPRING_PROFILES_ACTIVE="${SPRING_PROFILES_ACTIVE:-production}"
export YO3_LOG_LEVEL="${YO3_LOG_LEVEL:-INFO}"
export JAVA_OPTS="${JAVA_OPTS:--Xmx2G -Xms512M -XX:+UseG1GC}"

# Database configuration defaults
export IDENTITY_DB_URL="${IDENTITY_DB_URL:-jdbc:mysql://localhost:3306/teraapi_identity?useSSL=false&serverTimezone=UTC}"
export IDENTITY_DB_USER="${IDENTITY_DB_USER:-identity_user}"
export IDENTITY_DB_PASSWORD="${IDENTITY_DB_PASSWORD:-DevIdentityPass2024}"

export STREAM_DB_URL="${STREAM_DB_URL:-jdbc:mysql://localhost:3307/teraapi_stream?useSSL=false&serverTimezone=UTC}"
export STREAM_DB_USER="${STREAM_DB_USER:-stream_user}"
export STREAM_DB_PASSWORD="${STREAM_DB_PASSWORD:-DevStreamPass2024}"

export SENTINEL_DB_URL="${SENTINEL_DB_URL:-jdbc:postgresql://localhost:5432/sentinel}"
export SENTINEL_DB_USER="${SENTINEL_DB_USER:-sentinel_user}"
export SENTINEL_DB_PASSWORD="${SENTINEL_DB_PASSWORD:-DevSentinelPass2024}"

# Security
export JWT_SECRET="${JWT_SECRET:-7f213eab1c28432faec74d78f8f4d6c8b36a0d3c1f5e4a9c2d1f7b8e5c6a4d2}"
export YO3_MASTER_KEY="${YO3_MASTER_KEY:-dev-data-key-2024}"

# Service configuration
export DATA_CORE_PORT="${DATA_CORE_PORT:-9090}"
export EDGE_NODE_PORT="${EDGE_NODE_PORT:-8080}"
export IDENTITY_PORT="${IDENTITY_PORT:-8081}"
export STREAM_PORT="${STREAM_PORT:-8082}"
export MIDDLEWARE_PORT="${MIDDLEWARE_PORT:-8091}"
export FRONTEND_PORT="${FRONTEND_PORT:-5173}"

################################################################################
# Service Startup Functions
################################################################################

start_identity_service() {
    log "Starting Identity Service (port $IDENTITY_PORT)..."
    
    java $JAVA_OPTS \
        -Dspring.profiles.active=$SPRING_PROFILES_ACTIVE \
        -Dserver.port=$IDENTITY_PORT \
        -Dspring.datasource.url="$IDENTITY_DB_URL" \
        -Dspring.datasource.username="$IDENTITY_DB_USER" \
        -Dspring.datasource.password="$IDENTITY_DB_PASSWORD" \
        -Djwt.secret="$JWT_SECRET" \
        -jar /opt/yo3/services/identity-service.jar \
        > /opt/yo3/logs/identity-service.log 2>&1 &
    
    PIDS+=($!)
    SERVICES+=("Identity Service:$!")
    log_success "Identity Service started (PID: $!)"
}

start_data_core() {
    log "Waiting for Identity Service to be ready..."
    /opt/yo3/scripts/wait-for.sh localhost:$IDENTITY_PORT 30
    
    log "Starting Data Core (port $DATA_CORE_PORT)..."
    
    java $JAVA_OPTS \
        -Dspring.profiles.active=$SPRING_PROFILES_ACTIVE \
        -Dserver.port=$DATA_CORE_PORT \
        -Dyo3.storage.path=/opt/yo3/data/storage \
        -Dyo3.master.key="$YO3_MASTER_KEY" \
        -jar /opt/yo3/services/data-core.jar \
        > /opt/yo3/logs/data-core.log 2>&1 &
    
    PIDS+=($!)
    SERVICES+=("Data Core:$!")
    log_success "Data Core started (PID: $!)"
}

start_edge_node() {
    log "Starting Edge Node (port $EDGE_NODE_PORT)..."
    
    java $JAVA_OPTS \
        -Dspring.profiles.active=$SPRING_PROFILES_ACTIVE \
        -Dserver.port=$EDGE_NODE_PORT \
        -Dyo3.data.core.url="http://localhost:$DATA_CORE_PORT" \
        -Dyo3.device.id="${DEVICE_ID:-edge-node-001}" \
        -Dyo3.device.token="${DEVICE_TOKEN:-dev-token-2024}" \
        -jar /opt/yo3/services/edge-node.jar \
        > /opt/yo3/logs/edge-node.log 2>&1 &
    
    PIDS+=($!)
    SERVICES+=("Edge Node:$!")
    log_success "Edge Node started (PID: $!)"
}

start_stream_processing() {
    log "Waiting for Stream DB to be ready..."
    /opt/yo3/scripts/wait-for.sh localhost:3307 30
    
    log "Starting Stream Processing (port $STREAM_PORT)..."
    
    java $JAVA_OPTS \
        -Dspring.profiles.active=$SPRING_PROFILES_ACTIVE \
        -Dserver.port=$STREAM_PORT \
        -Dspring.datasource.url="$STREAM_DB_URL" \
        -Dspring.datasource.username="$STREAM_DB_USER" \
        -Dspring.datasource.password="$STREAM_DB_PASSWORD" \
        -Didentity.service.url="http://localhost:$IDENTITY_PORT" \
        -Djwt.secret="$JWT_SECRET" \
        -jar /opt/yo3/services/stream-processing.jar \
        > /opt/yo3/logs/stream-processing.log 2>&1 &
    
    PIDS+=($!)
    SERVICES+=("Stream Processing:$!")
    log_success "Stream Processing started (PID: $!)"
}

start_middleware() {
    log "Starting Middleware (port $MIDDLEWARE_PORT)..."
    
    java $JAVA_OPTS \
        -Dspring.profiles.active=$SPRING_PROFILES_ACTIVE \
        -Dserver.port=$MIDDLEWARE_PORT \
        -Dspring.datasource.url="$IDENTITY_DB_URL" \
        -Dspring.datasource.username="$IDENTITY_DB_USER" \
        -Dspring.datasource.password="$IDENTITY_DB_PASSWORD" \
        -Dmicrokernel.url="http://localhost:$DATA_CORE_PORT" \
        -Djwt.secret="$JWT_SECRET" \
        -jar /opt/yo3/services/middleware.jar \
        > /opt/yo3/logs/middleware.log 2>&1 &
    
    PIDS+=($!)
    SERVICES+=("Middleware:$!")
    log_success "Middleware started (PID: $!)"
}

start_frontend() {
    log "Starting Frontend (port $FRONTEND_PORT)..."
    
    # Frontend is served via simple HTTP server or embedded Node
    cd /opt/yo3/frontend/dist
    
    # Use Python's SimpleHTTPServer if available, otherwise Node
    if command -v python3 &> /dev/null; then
        python3 -m http.server $FRONTEND_PORT \
            > /opt/yo3/logs/frontend.log 2>&1 &
    else
        npx serve -l $FRONTEND_PORT \
            > /opt/yo3/logs/frontend.log 2>&1 &
    fi
    
    PIDS+=($!)
    SERVICES+=("Frontend:$!")
    log_success "Frontend started (PID: $!)"
}

################################################################################
# Main Startup Sequence
################################################################################

main() {
    clear
    
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║     YO3 Platform - Unified Container Orchestrator       ║"
    echo "║              Version 1.0.0 - Single Container Model     ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log "Starting YO3 Platform in $SPRING_PROFILES_ACTIVE mode..."
    echo ""
    
    # Create necessary directories
    mkdir -p /opt/yo3/data/storage /opt/yo3/logs
    
    # Start services in dependency order
    start_identity_service
    sleep 3
    
    start_data_core
    sleep 3
    
    start_edge_node
    sleep 2
    
    start_stream_processing
    sleep 2
    
    start_middleware
    sleep 2
    
    start_frontend
    sleep 3
    
    # Display startup summary
    echo ""
    log_success "All YO3 Platform services started!"
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Service Summary:${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    for service in "${SERVICES[@]}"; do
        echo -e "${GREEN}✓${NC} $service"
    done
    echo ""
    echo -e "${BLUE}Access Points:${NC}"
    echo -e "  • Frontend:           http://localhost:$FRONTEND_PORT"
    echo -e "  • Identity Service:   http://localhost:$IDENTITY_PORT"
    echo -e "  • Data Core:          http://localhost:$DATA_CORE_PORT"
    echo -e "  • Stream Processing:  http://localhost:$STREAM_PORT"
    echo -e "  • Middleware:         http://localhost:$MIDDLEWARE_PORT"
    echo -e "  • Edge Node:          http://localhost:$EDGE_NODE_PORT"
    echo ""
    echo -e "${YELLOW}Logs Location: /opt/yo3/logs/${NC}"
    echo -e "${YELLOW}Data Directory: /opt/yo3/data/${NC}"
    echo ""
    echo -e "${RED}Press Ctrl+C to shutdown YO3 Platform${NC}"
    echo ""
    
    # Wait for all services to continue running
    wait
}

# Run main function
main "$@"
