# eyeO Platform - Master Deployment Guide

**Version**: 1.0  
**Date**: January 2, 2026  
**Status**: Production-Ready (Professional Showcase)

---

## 🎯 Deployment Overview

This guide provides comprehensive instructions for deploying the complete eyeO platform using the master orchestration configuration. Designed for professional demonstration and career showcasing.

---

## 📋 Prerequisites Checklist

### System Requirements

- [ ] **Docker Desktop** 4.25+ (Windows/macOS) or Docker Engine 24+ (Linux)
- [ ] **Docker Compose** 2.20+
- [ ] **Java Development Kit** 21 (Amazon Corretto or OpenJDK)
- [ ] **Maven** 3.9+
- [ ] **Node.js** 18+ with npm
- [ ] **Git** 2.40+

### Resource Requirements

| Component | CPU | RAM | Disk |
|-----------|-----|-----|------|
| Databases (3) | 2 cores | 2 GB | 10 GB |
| Backend Services (4) | 4 cores | 4 GB | 5 GB |
| Frontend | 1 core | 512 MB | 1 GB |
| **Total** | **7 cores** | **6.5 GB** | **16 GB** |

### Network Requirements

- [ ] Ports available: 80, 443, 3306, 5173, 5432, 8081, 8082, 8090, 8091, 9090
- [ ] Internet access for Maven/npm dependencies
- [ ] Firewall allows Docker network bridge

---

## 🚀 Quick Start (5-Minute Deploy)

### Option 1: Automated Deployment Script

```powershell
# Clone repository (if not already done)
# cd D:\D_ORGANIZED\Development\Projects\eyeo-platform

# Run automated deployment with tests
.\deploy-with-tests.ps1

# Wait for all services to start (~3-5 minutes)
# Access dashboard: http://localhost:5173
```

### Option 2: Manual Step-by-Step

```powershell
# 1. Build all services
docker-compose -f docker-compose.master.yml build

# 2. Start databases first
docker-compose -f docker-compose.master.yml up -d identity-db stream-db sentinel-db

# 3. Wait for databases to initialize (30 seconds)
Start-Sleep -Seconds 30

# 4. Start backend services
docker-compose -f docker-compose.master.yml up -d identity-service stream-processing data-core

# 5. Start frontend and API gateway
docker-compose -f docker-compose.master.yml up -d frontend api-gateway

# 6. Verify all services are healthy
docker-compose -f docker-compose.master.yml ps
```

---

## 📦 Service Architecture

### Service Dependency Graph

```
┌─────────────────┐
│  API Gateway    │ :80, :443 (Nginx)
│  (Entry Point)  │
└────────┬────────┘
         │
    ┌────┴─────────────────────────────┐
    │                                  │
┌───▼──────────┐              ┌───────▼────────┐
│ Identity     │              │ Data Core      │
│ Service      │              │ (Protection)   │
│ :8081        │              │ :9090          │
└──────┬───────┘              └────────┬───────┘
       │                               │
       │         ┌─────────────────────┤
       │         │                     │
┌──────▼─────────▼──┐          ┌──────▼─────────┐
│ Stream Processing │          │ Frontend (UI)  │
│ :8082             │          │ :5173          │
└───────────────────┘          └────────────────┘
       │
       │
┌──────▼─────────┐
│   Databases    │
│ MySQL (x2)     │
│ PostgreSQL     │
└────────────────┘
```

### Service Endpoints

| Service | Internal Port | External Port | Purpose |
|---------|--------------|---------------|---------|
| **api-gateway** | 80, 443 | 80, 443 | Reverse proxy & SSL termination |
| **identity-service** | 8081 | - | Authentication & user management |
| **stream-processing** | 8082 | - | Event ingestion (Blue Flow) |
| **data-core** | 9090 | - | Stream protection (Red Flow) |
| **frontend** | 5173 | - | React dashboard |
| **identity-db** | 3306 | - | MySQL (identity data) |
| **stream-db** | 3307 | - | MySQL (events data) |
| **sentinel-db** | 5432 | - | PostgreSQL (middleware) |

---

## 🔧 Configuration

### Environment Variables

Copy and configure the environment template:

```powershell
Copy-Item .env.example .env
# Edit .env with your secure values
notepad .env
```

**Critical Variables to Set**:

```dotenv
# Production Environment
EYEO_ENV=production

# Security Keys (MUST CHANGE)
EYEO_MASTER_KEY=<generate-with-openssl-rand-base64-32>
JWT_SECRET_KEY=<generate-with-openssl-rand-base64-32>

# Database Passwords (MUST CHANGE)
POSTGRES_PASSWORD=<strong-password-16-chars-min>
IDENTITY_DB_PASSWORD=<strong-password-16-chars-min>
STREAM_DB_PASSWORD=<strong-password-16-chars-min>

# Storage Configuration
STORAGE_PATH=/protected-storage
STORAGE_TYPE=LOCAL  # or S3 for production
```

### Generate Secure Keys

**Linux/macOS**:
```bash
openssl rand -base64 32
```

**Windows PowerShell**:
```powershell
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }))
```

---

## 🧪 Health Checks & Verification

### Service Health Endpoints

```powershell
# Identity Service
curl http://localhost/api/auth/health

# Stream Processing
curl http://localhost/api/events/health

# Data Core
curl http://localhost/health

# Frontend
curl http://localhost/
```

### Expected Response

```json
{
  "status": "UP",
  "services": {
    "database": "UP",
    "storage": "UP",
    "processing": "UP"
  },
  "timestamp": 1704235200000
}
```

### Comprehensive Health Check Script

```powershell
# Check all services
$services = @(
    "http://localhost/api/auth/health",
    "http://localhost/health"
)

foreach ($service in $services) {
    try {
        $response = Invoke-RestMethod -Uri $service -Method Get
        Write-Host "✓ $service - Status: $($response.status)" -ForegroundColor Green
    } catch {
        Write-Host "✗ $service - FAILED" -ForegroundColor Red
    }
}
```

---

## 📊 Monitoring & Logs

### View Service Logs

```powershell
# All services
docker-compose -f docker-compose.master.yml logs -f

# Specific service
docker-compose -f docker-compose.master.yml logs -f identity-service

# Last 100 lines
docker-compose -f docker-compose.master.yml logs --tail=100 data-core
```

### Resource Usage

```powershell
# Container stats
docker stats

# Service-specific stats
docker stats eyeo-identity-service
```

### Database Connections

```powershell
# Connect to Identity DB
docker exec -it eyeo-identity-db mysql -uroot -p

# Connect to PostgreSQL
docker exec -it eyeo-sentinel-db psql -U sentinel_user -d sentinel
```

---

## 🔐 Security Hardening (Production)

### SSL/TLS Configuration

1. **Obtain SSL Certificate** (Let's Encrypt recommended)
   ```bash
   certbot certonly --standalone -d yourdomain.com
   ```

2. **Update Nginx Configuration**
   ```nginx
   # ops/nginx/nginx.conf
   ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
   ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
   ```

3. **Restart API Gateway**
   ```powershell
   docker-compose -f docker-compose.master.yml restart api-gateway
   ```

### Firewall Rules

```powershell
# Windows Firewall (allow only ports 80, 443)
New-NetFirewallRule -DisplayName "eyeO HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow
New-NetFirewallRule -DisplayName "eyeO HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
```

### Security Audit

```powershell
# Check for exposed secrets
git grep -i "password\|secret\|key" .env

# Verify no .env in version control
git ls-files | Select-String ".env"

# Check file permissions
icacls .env
```

---

## 🎨 Professional Showcase Mode

### Demo User Accounts

| Username | Password | Role | Purpose |
|----------|----------|------|---------|
| `demo@eyeo.com` | `Demo2024!` | ENTERPRISE | Full feature access |
| `pro@eyeo.com` | `Pro2024!` | PRO | Professional tier demo |
| `free@eyeo.com` | `Free2024!` | FREE | Basic tier demo |

### Sample Data Loading

```powershell
# Load demo detection events
curl -X POST http://localhost/api/v1/events `
  -H "Authorization: Bearer <token>" `
  -H "Content-Type: application/json" `
  -d @sample-data/detection-events.json

# Load demo stream metadata
curl -X POST http://localhost/stream/process `
  -H "Authorization: Bearer <token>" `
  -H "X-Session-ID: demo-session-001" `
  -H "X-Camera-ID: demo-camera-001" `
  --data-binary @sample-data/sample-video.mp4
```

### Presentation Mode

```powershell
# Start with clean state
docker-compose -f docker-compose.master.yml down -v
docker-compose -f docker-compose.master.yml up -d

# Load presentation data
.\scripts\load-demo-data.ps1

# Open dashboard
Start-Process "http://localhost:5173"
```

---

## 🛠️ Troubleshooting

### Common Issues

#### Issue: Port Already in Use

```powershell
# Find process using port
Get-NetTCPConnection -LocalPort 8081 | Select-Object OwningProcess
Get-Process -Id <PID> | Stop-Process

# Or change port in docker-compose.master.yml
```

#### Issue: Database Connection Failed

```powershell
# Check database status
docker-compose -f docker-compose.master.yml ps identity-db

# View database logs
docker-compose -f docker-compose.master.yml logs identity-db

# Restart database
docker-compose -f docker-compose.master.yml restart identity-db
```

#### Issue: Out of Memory

```powershell
# Check Docker resources
docker system df

# Cleanup unused resources
docker system prune -a --volumes

# Increase Docker Desktop memory (Settings > Resources)
```

#### Issue: Build Failures

```powershell
# Clean Maven cache
mvn clean install -U

# Rebuild without cache
docker-compose -f docker-compose.master.yml build --no-cache

# Check Java version
java -version  # Should be 21+
```

---

## 📈 Performance Optimization

### Database Tuning

```sql
-- MySQL (identity-db, stream-db)
SET GLOBAL innodb_buffer_pool_size = 1073741824; -- 1GB
SET GLOBAL max_connections = 200;

-- PostgreSQL (sentinel-db)
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
```

### Application Tuning

```yaml
# docker-compose.master.yml
services:
  identity-service:
    environment:
      - JAVA_OPTS=-Xmx512m -Xms256m
      - SPRING_PROFILES_ACTIVE=production
```

---

## 🔄 Backup & Recovery

### Automated Backup Script

```powershell
# backup-all.ps1
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

# Backup databases
docker exec eyeo-identity-db mysqldump -uroot -p$env:IDENTITY_DB_PASSWORD identity > "backups/identity-$timestamp.sql"
docker exec eyeo-stream-db mysqldump -uroot -p$env:STREAM_DB_PASSWORD stream > "backups/stream-$timestamp.sql"
docker exec eyeo-sentinel-db pg_dump -U sentinel_user sentinel > "backups/sentinel-$timestamp.sql"

# Backup protected storage
docker cp data-core:/protected-storage "backups/storage-$timestamp"

Write-Host "✓ Backup completed: $timestamp" -ForegroundColor Green
```

### Restore from Backup

```powershell
# Restore identity database
Get-Content "backups/identity-20260102-120000.sql" | docker exec -i eyeo-identity-db mysql -uroot -p$env:IDENTITY_DB_PASSWORD identity

# Restore storage
docker cp "backups/storage-20260102-120000" data-core:/protected-storage
```

---

## 📚 Additional Resources

- **OpenAPI Documentation**: http://localhost/swagger-ui.html
- **Architecture Diagram**: [ARCHITECTURE.md](ARCHITECTURE.md)
- **Security Policies**: [SECURITY.md](SECURITY.md)
- **API Testing Guide**: [API_TESTING_GUIDE.md](API_TESTING_GUIDE.md)
- **Public Showcase Guide**: [docs/PUBLIC_SHOWCASE_GUIDE.md](docs/PUBLIC_SHOWCASE_GUIDE.md)

---

## 🎯 Professional Demonstration Checklist

### Pre-Demo Setup

- [ ] All services running and healthy
- [ ] Demo user accounts created and tested
- [ ] Sample data loaded (events, streams)
- [ ] SSL certificate configured (if presenting remotely)
- [ ] Logs cleared for clean demonstration
- [ ] Dashboard customized with company branding (if applicable)

### Demo Flow

1. **Architecture Overview** (3 min)
   - Show service diagram
   - Explain Zero-Trust and SNA principles
   - Highlight split-brain data flows

2. **API Demonstration** (5 min)
   - Show OpenAPI documentation
   - Execute sample API calls (Postman/curl)
   - Demonstrate JWT authentication flow

3. **Live System** (7 min)
   - Login to dashboard
   - Show real-time detection events
   - Demonstrate license tier differences
   - Show audit log entries

4. **Technical Deep Dive** (5 min)
   - Show code samples (SecurityConfiguration, AuditLog)
   - Explain data protection strategy
   - Discuss scalability (SNA benefits)

### Post-Demo

- [ ] Provide GitHub repository links (public demos)
- [ ] Share OpenAPI specification
- [ ] Offer architecture diagram PDF
- [ ] Schedule follow-up technical discussion

---

## 🚨 Emergency Shutdown

```powershell
# Graceful shutdown (saves state)
docker-compose -f docker-compose.master.yml down

# Emergency stop (immediate)
docker-compose -f docker-compose.master.yml kill

# Complete cleanup (removes volumes)
docker-compose -f docker-compose.master.yml down -v
```

---

## 📞 Support & Contacts

**Project Lead**: [Your Name]  
**Email**: [your.email@example.com]  
**GitHub**: [github.com/yourusername/eyeo-platform]  
**LinkedIn**: [linkedin.com/in/yourprofile]

---

**Deployment Guide Version**: 1.0  
**Last Updated**: January 2, 2026  
**Tested On**: Docker 24.0.7, Windows 11, macOS 14, Ubuntu 22.04

---

**🎉 eyeO Platform is ready for professional showcase!**
