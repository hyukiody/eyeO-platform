# yo3 Platform - Deployment Package Documentation

**Generated:** 2026-01-03  
**Package Version:** 1.0-PARTIAL  
**Status:** 3/6 Services Ready for Deployment

---

## 📦 Package Contents

### Container Images (213 MB Total)

✅ **Available Images** (3/6):
- `yo3-frontend.tar` (22.05 MB) - React/Vite frontend application
- `yo3-identity.tar` (121.67 MB) - JWT authentication service  
- `yo3-data-core.tar` (69.56 MB) - Secure I/O video processing engine

⏸️ **Pending Builds** (3/6):
- `yo3-middleware.tar` - Image Inverter gatekeeper
- `yo3-edge-node.tar` - Video capture and streaming
- `yo3-stream.tar` - Real-time event detection

### Deployment Files

- `docker-compose.yml` - Complete orchestration configuration (all 9 services)
- `.env.example` - Security configuration template
- `deploy.ps1` - Windows PowerShell deployment automation (196 lines)
- `deploy.sh` - Linux/Bash deployment automation (174 lines)
- `README.md` - Complete deployment guide (423 lines)
- `SHA256SUMS.txt` - Image integrity checksums

---

## 🚀 Quick Start (Partial Deployment)

### Prerequisites
- Docker Engine 20.10+ or Docker Desktop
- Docker Compose 2.0+
- 4GB RAM minimum, 8GB recommended
- 10GB disk space

### 1. Load Available Images

**Windows:**
```powershell
cd deployment-package\images
docker load -i yo3-frontend.tar
docker load -i yo3-identity.tar
docker load -i yo3-data-core.tar
```

**Linux/Mac:**
```bash
cd deployment-package/images
docker load < yo3-frontend.tar
docker load < yo3-identity.tar  
docker load < yo3-data-core.tar
```

### 2. Configure Environment

```powershell
cp .env.example .env
# Edit .env and set:
# - DB_PASSWORD (strong password, 16+ characters)
# - JWT_SECRET (256-bit random string)
# - yo3_MASTER_KEY (generate with: openssl rand -base64 32)
```

### 3. Deploy Core Services

```powershell
# Start databases and frontend
docker-compose up -d identity-db stream-db sentinel-db frontend

# Start Java services (if images available)
docker-compose up -d identity-service secure-io-engine
```

---

## ⚠️ Known Issues & Troubleshooting

### Maven Build Performance

**Problem:** Maven dependency downloads extremely slow (~46 kB/s) during Docker builds

**Impact:** middleware, edge-node, stream-processing builds timeout after 10-15 minutes

**Solutions:**

**Option A: Build on Host Machine (Fastest)**
```powershell
# Navigate to each service directory
cd middleware
mvn clean package -DskipTests  # Uses local Maven cache

cd ../edge-node
mvn clean package -DskipTests

cd ../stream-processing
mvn clean package -DskipTests

# Rebuild Docker images with pre-built JARs
cd ..
docker-compose build image-inverter yo3-edge-node stream-processing
```

**Option B: Maven Mirror Configuration**
Create `settings.xml` in each service directory:
```xml
<settings>
  <mirrors>
    <mirror>
      <id>aliyun</id>
      <mirrorOf>central</mirrorOf>
      <url>https://maven.aliyun.com/repository/central</url>
    </mirror>
  </mirrors>
</settings>
```

**Option C: Build Overnight**
Run builds when network bandwidth is higher (off-peak hours)

### Identity Service Restart Loop

**Symptom:** identity-service container keeps restarting  
**Cause:** Database connection failure or missing environment variables

**Fix:**
```powershell
# Check logs
docker-compose logs identity-service

# Verify database is healthy
docker-compose ps identity-db

# Ensure .env has required variables
IDENTITY_DB_PASSWORD=...
JWT_SECRET=...
IDENTITY_MYSQL_ROOT_PASSWORD=...
```

### Data Core "Unhealthy" Status

**Symptom:** yo3-data-core shows "unhealthy" in `docker-compose ps`  
**Cause:** Health check endpoint may be at different path

**Verification:**
```powershell
# Check if service is actually running
docker-compose logs secure-io-engine
# Should show: "Microkernel Security Engine (Commercial) started on port 8080"

# Test manually
docker exec yo3-data-core wget -q -O- http://localhost:8080/health
```

---

## 🏗️ Completing the Deployment

### Build Remaining Services

**Step 1: Install Maven** (if not available)
```powershell
# Download from https://maven.apache.org/download.cgi
# Or use Chocolatey: choco install maven
```

**Step 2: Build JARs Locally**
```powershell
cd D:\path\to\yo3-platform

# Middleware
cd middleware
mvn clean package -DskipTests
# Expected output: BUILD SUCCESS, target/image-inverter-1.0.0.jar

# Edge Node  
cd ../edge-node
mvn clean package -DskipTests
# Expected output: BUILD SUCCESS, target/edge-node-1.0.0.jar

# Stream Processing
cd ../stream-processing
mvn clean package -DskipTests
# Expected output: BUILD SUCCESS, target/stream-processing-1.0.0.jar
```

**Step 3: Build Docker Images**
```powershell
cd ..
docker-compose build image-inverter yo3-edge-node stream-processing
```

**Step 4: Export New Images**
```powershell
.\export-images.ps1
# Will add 3 new .tar files to deployment-package/images/
```

**Step 5: Deploy Complete Stack**
```powershell
docker-compose up -d
docker-compose ps  # Verify all 9 containers running
```

---

## 🧪 Testing Deployed Services

### Test Frontend
```powershell
# If using API gateway (port 80)
Start-Process "http://localhost"

# Direct access (if exposed)
Start-Process "http://localhost:5173"
```

### Test Identity Service
```powershell
# Health check
Invoke-WebRequest http://localhost:8081/actuator/health

# Register user
$body = @{
    email = "test@yo3.com"
    password = "SecurePass123!"
    fullName = "Test User"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:8081/api/auth/register" `
    -Method POST -Body $body -ContentType "application/json"

# Login
$loginBody = @{
    email = "test@yo3.com"
    password = "SecurePass123!"
} | ConvertTo-Json

$token = Invoke-RestMethod -Uri "http://localhost:8081/api/auth/login" `
    -Method POST -Body $loginBody -ContentType "application/json"

Write-Host "JWT Token: $($token.token)"
```

### Test Data Core
```powershell
# Check logs for startup message
docker-compose logs secure-io-engine | Select-String "started"

# Should see: "Microkernel Security Engine (Commercial) started on port 8080"
```

---

## 📊 Service Architecture

```
┌─── EXTERNAL ACCESS ────────────────────────────┐
│  API Gateway (Nginx)                           │
│  Ports: 80/443                                 │
│  - SSL/TLS Termination                         │
│  - Reverse Proxy to Backend Services           │
└────────────────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
┌───── FRONTEND ─────┐   ┌──── AUTH ─────┐
│  yo3-frontend     │   │  identity-    │
│  Port: 5173        │   │  service      │
│  Status: ✅ READY  │   │  Port: 8081   │
└────────────────────┘   │  Status: ⚠️   │
                         └───────────────┘
                               │
        ┌──────────────────────┼──────────────┐
        │                      │              │
┌──── VIDEO PROCESSING ────┐ ┌─ MIDDLEWARE ─┐│
│  secure-io-engine        │ │  image-      ││
│  (Data Core)             │ │  inverter    ││
│  Port: 8080 (internal)   │ │  Port: 8091  ││
│  Status: ✅ RUNNING      │ │  Status: ⏸️  ││
└──────────────────────────┘ └──────────────┘│
        │                                     │
┌──── EDGE CAPTURE ────┐   ┌─ STREAM PROC ──┐
│  yo3-edge-node      │   │  stream-       │
│  Port: 8080          │   │  processing    │
│  Status: ⏸️ PENDING  │   │  Port: 8082    │
└──────────────────────┘   │  Status: ⏸️    │
                           └────────────────┘
        │                      │          │
┌───── DATABASES ──────────────────────────────┐
│  identity-db (MySQL)       ✅ HEALTHY        │
│  sentinel-db (PostgreSQL)  ✅ HEALTHY        │
│  stream-db (MySQL)         ✅ HEALTHY        │
└───────────────────────────────────────────────┘
```

---

## 📈 Deployment Metrics

| Metric | Value |
|--------|-------|
| **Total Services** | 9 (6 apps + 3 DBs) |
| **Ready to Deploy** | 6 (Frontend + 2 Java + 3 DBs) |
| **Pending Builds** | 3 Java services |
| **Deployment Progress** | 67% |
| **Image Export Progress** | 50% (3/6) |
| **Package Size** | 213 MB (current) |
| **Estimated Full Size** | 450-500 MB |

---

## 🔐 Zero-Trust Architecture Features

**Implemented:**
- ✅ CaCTUs (Coding at Capture, Trusting upon Show) architecture
- ✅ Master key never transmitted over network
- ✅ Video content encoded at edge node
- ✅ Blind storage in microkernel
- ✅ Web Worker-based client-side decoding
- ✅ QR code-based device pairing (Seeing-Is-Believing)
- ✅ IndexedDB secure key storage

**Testing Status:**
- ⏸️ End-to-end video flow (requires all services)
- ✅ Frontend QR pairing component ready
- ✅ Video player with decryption ready
- ⏸️ Edge node frame capture (pending build)
- ⏸️ Stream processing metadata (pending build)

---

## 📝 Next Steps

### Immediate (For Partial Deployment)
1. ✅ Load 3 available images
2. ✅ Configure .env file
3. ✅ Start databases and frontend
4. ⚠️ Fix identity-service database connection
5. ✅ Verify data-core running

### Short-term (Complete Build)
1. Install Maven or use host machine builds
2. Build 3 remaining services locally
3. Create Docker images with pre-built JARs
4. Export remaining 3 images
5. Test full 9-service stack

### Long-term (Production Ready)
1. Configure SSL certificates for API gateway
2. Set up monitoring (Prometheus/Grafana)
3. Implement log aggregation
4. Configure backup strategies
5. Load testing and performance tuning
6. Security audit and penetration testing

---

## 📞 Support & Documentation

- **Full Deployment Guide:** `README.md` (423 lines)
- **API Testing Guide:** `../API_TESTING_GUIDE.md`
- **Build Troubleshooting:** This document (Issues section)
- **Architecture Docs:** `../docs/` directory

---

## ✅ Deployment Checklist

**Pre-Deployment:**
- [ ] Docker Engine/Desktop installed and running
- [ ] 10GB free disk space available
- [ ] `.env` file configured with secrets
- [ ] Firewall rules configured (if applicable)

**Deployment Steps:**
- [x] Load available images (3/6)
- [ ] Load remaining images (0/3)
- [x] Start database containers
- [x] Verify database health checks
- [ ] Start application containers
- [ ] Verify application health checks
- [ ] Test authentication flow
- [ ] Test Zero-Trust video flow
- [ ] Configure monitoring

**Post-Deployment:**
- [ ] Verify all 9 containers running
- [ ] Test all API endpoints
- [ ] Backup configuration files
- [ ] Document any custom changes
- [ ] Schedule regular backups

---

**Package Generated:** 2026-01-03 18:00 UTC-3  
**Build Environment:** Windows Docker Desktop 28.3.2  
**Docker Compose Version:** 2.x
