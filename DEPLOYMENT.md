# YO3 Platform - Deployment Guide

## Overview

YO3 Platform is a distributed edge computing and real-time stream processing system designed for low-latency data ingestion, processing, and distribution across heterogeneous networks.

**Key Features:**
- Single-container orchestrated deployment
- Multi-service architecture (6 services coordinated internally)
- Multi-database support (MySQL 8.0, PostgreSQL 16)
- Horizontal scalability at edge nodes
- Health-checked service management
- Docker-based containerization with Compose orchestration

## Architecture

### Services
1. **data-core** (Port 9090) - Central data repository and query engine
2. **edge-node** (Port 8080) - Edge node for distributed processing
3. **identity-service** (Port 8081) - Authentication and authorization
4. **stream-processing** (Port 8082) - Real-time stream processing engine
5. **middleware** (Port 8091) - API gateway and service coordination
6. **frontend** (Port 80/5173) - React-based web UI

### Databases
- **Identity DB**: MySQL 8.0 (Port 3306)
- **Stream DB**: MySQL 8.0 (Port 3307)
- **Sentinel DB**: PostgreSQL 16 (Port 5432)

### Orchestration Model
- **Single Container**: All 6 services run within a single `yo3-platform` container
- **Process Management**: `orchestrator.sh` (PID 1) manages service lifecycle
- **Health Monitoring**: Built-in health checks for service availability
- **Port Exposure**: All service ports exposed via docker-compose

## Prerequisites

- Docker 28.0+ and Docker Compose 2.20+
- 8GB RAM minimum (12GB+ recommended)
- 50GB disk space for images and volumes
- Windows 10/11, macOS 10.15+, or Linux (kernel 5.4+)

## Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/your-org/yo3-platform.git
cd yo3-platform
```

### 2. Deploy with Docker Compose
```bash
# Start all services (databases + orchestrator)
docker-compose -f docker-compose.orchestrator.yml up -d

# Verify all containers are running
docker-compose -f docker-compose.orchestrator.yml ps

# Follow logs (shows service initialization)
docker-compose -f docker-compose.orchestrator.yml logs -f
```

### 3. Access Services
- **Frontend**: http://localhost
- **Frontend (Alt)**: http://localhost:5173
- **Identity Service**: http://localhost:8081
- **Data Core**: http://localhost:8080 or :9090
- **Stream Processing**: http://localhost:8082
- **Middleware**: http://localhost:8091

### 4. Verify Health
```bash
# Check container health
docker-compose -f docker-compose.orchestrator.yml ps

# Check service logs
docker logs <container_id>

# Test endpoints
curl http://localhost/health
curl http://localhost:8081/health
curl http://localhost:8080/health
```

## Detailed Setup

### Environment Variables

Create `.env` file in project root:

```env
# Docker Image Configuration
DOCKER_REGISTRY=docker.io
DOCKER_NAMESPACE=your-org
DOCKER_IMAGE_NAME=yo3-platform
DOCKER_IMAGE_TAG=latest

# Database Configuration
MYSQL_ROOT_PASSWORD=root_password_here
MYSQL_DATABASE=yo3_main
POSTGRES_PASSWORD=postgres_password_here

# Service Configuration
LOG_LEVEL=INFO
DEBUG_MODE=false
```

### Database Setup

Databases are automatically initialized via `init-db.sql` script:

```sql
-- Identity database (MySQL 8.0)
CREATE DATABASE yo3_identity;

-- Stream processing database (MySQL 8.0)
CREATE DATABASE yo3_streams;

-- Sentinel database (PostgreSQL 16)
CREATE DATABASE yo3_sentinel;
```

### Network Configuration

Services communicate via internal `yo3_network` bridge:

```yaml
networks:
  yo3_network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

## Production Deployment

### 1. Docker Hub Push

```bash
# Login to Docker Hub
docker login

# Tag image for Docker Hub
docker tag yo3-platform:latest your-docker-username/yo3-platform:v1.0.0
docker tag yo3-platform:latest your-docker-username/yo3-platform:latest

# Push images
docker push your-docker-username/yo3-platform:v1.0.0
docker push your-docker-username/yo3-platform:latest
```

### 2. Kubernetes Deployment

For Kubernetes, use the provided Helm chart:

```bash
helm install yo3 ./helm/yo3-platform \
  --namespace default \
  --values ./helm/values.yaml
```

### 3. Azure Container Instances

```bash
az container create \
  --resource-group myResourceGroup \
  --name yo3-platform \
  --image myregistry.azurecr.io/yo3-platform:latest \
  --cpu 4 --memory 8 \
  --ports 80 8080 8081 8082 8091 3306 3307 5432
```

### 4. AWS ECS

```bash
aws ecs create-service \
  --cluster yo3-cluster \
  --service-name yo3-platform \
  --task-definition yo3-platform:1 \
  --desired-count 2 \
  --load-balancers targetGroupArn=arn:aws:elasticloadbalancing:...
```

## Configuration

### Service Configuration

Edit service-specific config files:

- **Data Core**: `data-core/src/main/resources/application.properties`
- **Edge Node**: `edge-node/application.properties`
- **Identity Service**: `identity-service/src/main/resources/application.properties`
- **Stream Processing**: `stream-processing/src/main/resources/application.properties`
- **Middleware**: `middleware/src/main/resources/application.properties`
- **Frontend**: `frontend/vite.config.ts`

### Orchestrator Configuration

Modify `scripts/orchestrator/orchestrator.sh`:

```bash
# Service startup sequence
data_core
edge_node
identity_service
stream_processing
middleware
frontend
```

## Monitoring & Debugging

### View Logs

```bash
# All services
docker-compose -f docker-compose.orchestrator.yml logs

# Specific service
docker logs yo3-platform

# Follow logs in real-time
docker-compose -f docker-compose.orchestrator.yml logs -f yo3-platform
```

### Health Checks

```bash
# Check orchestrator health
curl http://localhost:9090/health

# Check database connectivity
docker exec yo3-identity-db mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "SELECT 1"
docker exec yo3-stream-db mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "SELECT 1"
docker exec yo3-sentinel-db psql -U postgres -c "SELECT 1"
```

### Performance Metrics

```bash
# Docker container stats
docker stats yo3-platform

# Resource usage
docker inspect yo3-platform | grep -A 20 '"Stats"'
```

## Troubleshooting

### Issue: Container fails to start

**Solution:**
```bash
# Check logs for errors
docker logs yo3-platform

# Verify database connectivity
docker exec yo3-platform curl http://localhost:3306

# Restart container
docker-compose -f docker-compose.orchestrator.yml restart yo3-platform
```

### Issue: Services not responding

**Solution:**
```bash
# Check service status inside container
docker exec yo3-platform ps aux

# Test service connectivity
docker exec yo3-platform curl http://localhost:8080/health

# Check network
docker network inspect yo3_network
```

### Issue: High memory usage

**Solution:**
```bash
# Increase Docker memory limit
docker update --memory 8g yo3-platform

# Restart container
docker-compose -f docker-compose.orchestrator.yml restart yo3-platform
```

## Scaling

### Horizontal Scaling (Multiple Instances)

```bash
# Deploy multiple edge nodes
docker-compose -f docker-compose.orchestrator.yml up -d --scale edge-node=3
```

### Vertical Scaling (Increase Resources)

```bash
# Update docker-compose.yml resource limits
services:
  yo3-platform:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G
```

## Backup & Recovery

### Backup Databases

```bash
# MySQL backup
docker exec yo3-identity-db mysqldump -uroot -p$MYSQL_ROOT_PASSWORD --all-databases > backup.sql

# PostgreSQL backup
docker exec yo3-sentinel-db pg_dump -U postgres > backup.sql
```

### Restore Databases

```bash
# MySQL restore
docker exec -i yo3-identity-db mysql -uroot -p$MYSQL_ROOT_PASSWORD < backup.sql

# PostgreSQL restore
docker exec -i yo3-sentinel-db psql -U postgres < backup.sql
```

## Security Considerations

### Network Security
- Use firewall rules to restrict port access
- Enable TLS/SSL for external communications
- Isolate database containers on internal network

### Secret Management
- Store sensitive config in `.env` (never commit)
- Use Docker secrets for production
- Rotate database passwords regularly

### Image Security
- Scan images for vulnerabilities: `docker scan yo3-platform:latest`
- Use specific version tags (not `latest`)
- Keep base images updated

## Support & Contributing

For issues, questions, or contributions:
- **Issues**: GitHub Issues
- **Documentation**: See `DOCUMENTATION.md`
- **Contributing**: See `CONTRIBUTING.md`
- **License**: See `LICENSE`

## Version History

### v1.0.0 (Current)
- Initial stable release
- Single-container orchestration
- Multi-database support
- Docker Compose deployment
- Health checks and monitoring

## Next Steps

1. **Customize Configuration**: Adjust service configs for your environment
2. **Set Up Monitoring**: Implement Prometheus/Grafana for metrics
3. **Configure Persistence**: Set up volume backups
4. **Security Hardening**: Enable authentication and encryption
5. **Scaling**: Deploy multiple instances for production load

---

For more information, see:
- [Quick Start Guide](QUICK_START.md)
- [Complete Documentation](DOCUMENTATION.md)
- [Development Guide](DEVELOPMENT_READY.md)
