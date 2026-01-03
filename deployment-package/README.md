# yo3 Platform - Production Deployment Package

**Version**: 1.0.0  
**Date**: January 3, 2026  
**Architecture**: CaCTUs Zero-Trust Surveillance System

## 📦 Package Contents

```
deployment-package/
├── images/                      # Docker images (.tar files)
│   ├── yo3-data-core.tar      # 9090 - Video encoding microkernel
│   ├── yo3-edge-node.tar      # 8080 - Video capture + YOLO
│   ├── yo3-identity.tar       # 8081 - JWT authentication
│   ├── yo3-middleware.tar     # 8091 - Event processing
│   ├── yo3-stream.tar         # 8082 - Metadata ingestion
│   └── yo3-frontend.tar       # 5173 - React dashboard
├── docker-compose.yml          # Orchestration configuration
├── .env.example                # Environment variables template
├── deploy.ps1                  # Windows deployment script
├── deploy.sh                   # Linux deployment script
└── README.md                   # This file
```

## 🏗️ Architecture Overview

### CaCTUs Zero-Trust Model

**Split-Brain Architecture:**
- **Red Flow**: Encoded video (Edge → Microkernel → Storage)
- **Blue Flow**: Metadata only (Edge → Middleware → Frontend)

**Security Principles:**
- ✅ Zero-Trust: Edge nodes NEVER encode locally
- ✅ Seeing-Is-Believing: QR code device pairing
- ✅ Client-Side Processing: Master keys in IndexedDB
- ✅ Blind Storage: Cloud stores without decryption capability

### Service Ports

| Service | Port | Purpose |
|---------|------|---------|
| data-core | 9090 | AES-256-GCM video encoding (ONLY encoding service) |
| edge-node | 8080 | Video capture + YOLOv8 object detection |
| identity-service | 8081 | JWT authentication |
| stream-processing | 8082 | Blue Flow metadata ingestion |
| middleware | 8091 | Event processing gateway |
| frontend | 5173 | React dashboard (development) |
| api-gateway | 80/443 | Nginx reverse proxy (production) |

## 🚀 Quick Start

### Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- 8GB RAM minimum
- 20GB disk space

### 1. Load Images

**Windows (PowerShell):**
```powershell
Get-ChildItem .\images\*.tar | ForEach-Object { docker load -i $_.FullName }
```

**Linux/Mac:**
```bash
for img in images/*.tar; do docker load -i "$img"; done
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with production values
```

**Critical Variables:**
- `JWT_SECRET`: Strong random secret (min 32 chars)
- `DB_PASSWORD`: Database root password
- `yo3_MASTER_KEY`: Master encoding key
- `DEVICE_TOKEN`: Edge node authentication token

### 3. Deploy

**Windows:**
```powershell
.\deploy.ps1
```

**Linux/Mac:**
```bash
chmod +x deploy.sh
./deploy.sh
```

### 4. Verify

```bash
docker-compose ps
curl http://localhost:8081/api/health
```

## 🔐 Security Configuration

### Database Security

**PostgreSQL (stream-processing):**
```yaml
STREAM_DB_USERNAME: stream_user
STREAM_DB_PASSWORD: <generate-strong-password>
```

**MySQL (identity-service, middleware):**
```yaml
IDENTITY_DB_PASSWORD: <generate-strong-password>
MIDDLEWARE_DB_PASSWORD: <generate-strong-password>
```

### JWT Configuration

```yaml
JWT_SECRET: <min-256-bit-random-string>
JWT_EXPIRATION: 3600000  # 1 hour in milliseconds
```

### Edge Node Authentication

```yaml
DEVICE_TOKEN: yo3-edge-<unique-id>-<random-suffix>
```

## 📊 Monitoring

### Health Endpoints

- Identity: `http://localhost:8081/api/health`
- Data-Core: `http://localhost:9090/api/health`
- Stream: `http://localhost:8082/api/health`
- Middleware: `http://localhost:8091/api/health`

### Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f data-core
docker-compose logs -f edge-node
```

### Performance Metrics

```bash
docker stats
```

## 🔄 Zero-Trust Video Flow

### 1. Video Capture (Edge Node)
```
Edge Node (8080) → Captures video frame
              ↓
         YOLO Detection (local)
              ↓
         Export raw frame via HTTP POST
```

### 2. Encoding (Microkernel)
```
Data-Core (9090) → Receives raw frame
                ↓
         AES-256-GCM encoding
                ↓
         Returns storage reference
```

### 3. Metadata Ingestion (Blue Flow)
```
Edge Node → Detection metadata
         ↓
   Middleware (8091) → Event processing
                    ↓
         Stream-Processing (8082) → Database storage
```

### 4. Client Playback
```
Frontend → Fetches encoded video from data-core
        ↓
   Web Worker → AES-GCM decryption (master key from IndexedDB)
             ↓
        Video element → Playback
```

## 🛠️ Troubleshooting

### Container Won't Start

```bash
docker-compose logs <service-name>
docker inspect <container-id>
```

### Database Connection Issues

```bash
# Check database is running
docker-compose ps | grep mysql
docker-compose ps | grep postgres

# Test connection
docker-compose exec identity-mysql mysql -uroot -p
docker-compose exec stream-db psql -U stream_user -d stream_processing
```

### Port Conflicts

```bash
# Check what's using port
netstat -ano | findstr :8080  # Windows
lsof -i :8080                 # Linux/Mac

# Change port in docker-compose.yml
```

### Image Loading Failures

```bash
# Verify image integrity
sha256sum images/*.tar  # Linux
Get-FileHash images\*.tar -Algorithm SHA256  # Windows

# Manual load
docker load -i images/yo3-data-core.tar
docker images | grep yo3
```

## 📁 Volumes & Data Persistence

```yaml
volumes:
  mysql-identity-data:    # Identity service database
  mysql-middleware-data:  # Middleware database
  postgres-stream-data:   # Stream processing database
  video-storage:          # Encoded video storage
```

**Backup:**
```bash
docker run --rm -v yo3-platform_mysql-identity-data:/data -v $(pwd):/backup alpine tar czf /backup/identity-db-backup.tar.gz /data
```

## 🔧 Advanced Configuration

### Custom Network

```yaml
networks:
  yo3-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.25.0.0/16
```

### Resource Limits

```yaml
services:
  data-core:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
```

### SSL/TLS (Production)

```yaml
api-gateway:
  ports:
    - "443:443"
  volumes:
    - ./certs:/etc/nginx/certs:ro
```

## 📞 Support

**Architecture**: CaCTUs Zero-Trust Model  
**Framework**: Spring Boot 3.2.1 + React 18  
**Database**: MySQL 8.0 + PostgreSQL 16  
**Container**: Docker 28.3.2

## 📝 License

Proprietary - yo3 Surveillance Platform © 2026

---

**Deployment Checklist:**

- [ ] Load all Docker images
- [ ] Configure .env with production secrets
- [ ] Update JWT_SECRET (min 32 chars)
- [ ] Set strong database passwords
- [ ] Generate unique DEVICE_TOKEN
- [ ] Review port mappings
- [ ] Run deployment script
- [ ] Verify all services healthy
- [ ] Test video flow: Edge → Microkernel → Frontend
- [ ] Test device pairing with QR code
- [ ] Configure backup strategy
- [ ] Setup monitoring/alerting

**Security Verification:**

- [ ] Edge node does NOT encode locally
- [ ] All video passes through Microkernel (9090)
- [ ] Master keys stored in browser IndexedDB only
- [ ] QR pairing workflow functional
- [ ] JWT tokens expire correctly
- [ ] Database access restricted
- [ ] HTTPS enabled (production)
