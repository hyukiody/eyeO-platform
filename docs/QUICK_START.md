# eyeO Platform Quick Start Guide

## 🚀 Quick Start (5 Minutes)

### Prerequisites
```bash
# Required
- JDK 17+
- Node.js 18+
- Docker Desktop (running)
- MySQL 8.0 (via Docker)
```

### 1. Database Setup (First Time Only)
```bash
cd eyeo-platform

# Start MySQL via Docker
docker-compose up -d mysql-identity mysql-stream

# Wait 30 seconds for MySQL initialization
# Flyway migrations run automatically on service startup
```

### 2. Backend Services
```bash
# Terminal 1: Identity Service (Port 8081)
cd identity-service
mvn spring-boot:run

# Terminal 2: Data Core (Port 8082)
cd data-core
mvn spring-boot:run

# Terminal 3: Stream Processing (Port 8083)
cd stream-processing
mvn spring-boot:run
```

### 3. Frontend
```bash
# Terminal 4: React Frontend (Port 5173)
cd frontend
npm install
npm run dev
```

### 4. Access the Platform
```
🌐 Frontend: http://localhost:5173
📡 Identity API: http://localhost:8081
💾 Data Core API: http://localhost:8082
📹 Stream API: http://localhost:8083
```

---

## 🎯 Test the Monetization Features

### Create a FREE Trial Account
1. Navigate to http://localhost:5173/login
2. Click **"Sign Up"**
3. Fill in:
   - Username: `testuser`
   - Email: `test@eyeo.com`
   - Password: `Test1234!`
   - Seed Key: `aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa` (32 chars minimum)
4. Click **"Sign Up"** → Redirects to Dashboard

### Test Quota Enforcement

#### Test Camera Quota (FREE = 1 camera max)
```bash
# Get token from browser localStorage or login response
TOKEN="your-jwt-token-here"

# Add first camera (SUCCESS)
curl -X POST http://localhost:8083/cameras \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Camera 1","rtspUrl":"rtsp://demo.com/stream1"}'

# Add second camera (FAIL - quota exceeded)
curl -X POST http://localhost:8083/cameras \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Camera 2","rtspUrl":"rtsp://demo.com/stream2"}'
# Expected: HTTP 402 Payment Required
```

#### Test Storage Quota (FREE = 5GB max)
```bash
# Upload small video (SUCCESS if < 5GB total)
curl -X POST http://localhost:8082/storage/encrypt \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@test-video.mp4"

# Check quota usage
curl http://localhost:8082/quota/usage \
  -H "Authorization: Bearer $TOKEN"
# Response: {"storage":{"currentGb":0.25,"maxGb":5.0,"percentage":5.0}}
```

#### Test FREE Tier Watermark
```bash
# Encrypted videos for FREE tier include "DEMO VERSION" watermark
# Download and decrypt a video to verify
curl http://localhost:8082/storage/{storageKey} \
  -H "Authorization: Bearer $TOKEN" \
  --output encrypted.bin
```

### Test Trial Expiration
```bash
# Trials expire after 14 days
# To test expiration, manually update database:

docker exec -it mysql-identity mysql -u root -prootpassword

USE eyeo_identity;
UPDATE users 
SET trial_end_date = NOW() - INTERVAL 1 DAY 
WHERE username = 'testuser';

# Now login attempts will fail with "Trial expired" message
```

---

## 🔍 Verify Implementation

### Check Backend Logs
```bash
# Identity Service - Watch for license validation
tail -f identity-service/logs/application.log | grep "License"

# Expected output on login:
# INFO: License validated for user=testuser, tier=FREE, trial expires in 13 days
```

### Check Frontend State
```javascript
// Open browser console (F12)
localStorage.getItem('token')  // JWT token
localStorage.getItem('seedKey') // Encryption seed

// Decode JWT to see claims
const token = localStorage.getItem('token');
const payload = JSON.parse(atob(token.split('.')[1]));
console.log(payload);
/* Output:
{
  "sub": "test@eyeo.com",
  "username": "testuser",
  "licenseTier": "FREE",
  "maxCameras": 1,
  "maxStorageGb": 5,
  "apiRateLimit": 10,
  "features": ["storage.local", "ai.detection.simulated"],
  "exp": 1735660800
}
*/
```

### Test Dashboard Features
1. **Quota Display**: Should show 0/1 cameras, 0/5GB storage
2. **Trial Warning**: If < 3 days remaining, orange banner appears
3. **Upgrade Button**: Click shows "Upgrade Plan" (future billing integration)
4. **Camera List**: Empty state with "No cameras configured"
5. **Events Timeline**: Mock events until real AI detection added

---

## 📊 Database Verification

### Check Monetization Schema
```sql
-- Connect to MySQL
docker exec -it mysql-identity mysql -u root -prootpassword

USE eyeo_identity;

-- Verify monetization fields exist
DESCRIBE users;
-- Expected columns: license_tier, max_cameras, max_storage_gb, api_rate_limit, trial_end_date, stripe_customer_id, stripe_subscription_id, subscription_status

-- Check Flyway migrations
SELECT * FROM flyway_schema_history;
-- Expected: V1__Initial_schema.sql, V2__add_monetization_fields.sql

-- View user data
SELECT id, username, license_tier, max_cameras, max_storage_gb, trial_end_date 
FROM users;
```

### Check Subscription Table
```sql
SELECT * FROM subscriptions;
-- Empty until Stripe integration is complete (Phase 2.5)
```

---

## 🐛 Troubleshooting

### Issue: Frontend shows "Failed to load dashboard data"
**Solution**: Check backend services are running
```bash
# Verify all services respond
curl http://localhost:8081/actuator/health
curl http://localhost:8082/actuator/health
curl http://localhost:8083/actuator/health

# Expected: {"status":"UP"}
```

### Issue: "License expired" on login
**Solution**: Check trial_end_date in database
```sql
UPDATE users 
SET trial_end_date = NOW() + INTERVAL 14 DAY 
WHERE username = 'testuser';
```

### Issue: CORS errors in browser console
**Solution**: Update application.properties
```properties
# identity-service/src/main/resources/application.properties
server.cors.allowed-origins=http://localhost:5173
```

### Issue: Video decryption fails
**Solution**: Verify seed key matches
```javascript
// Browser console
localStorage.setItem('seedKey', 'your-32-char-seed-key-here');
```

### Issue: MySQL connection refused
**Solution**: Start Docker containers
```bash
docker-compose up -d mysql-identity mysql-stream
docker ps  # Verify containers running
```

---

## 📚 API Endpoints Reference

### Identity Service (Port 8081)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register` | Create trial account |
| POST | `/auth/login` | Authenticate user |
| GET | `/auth/me` | Get current user |
| POST | `/auth/refresh` | Refresh JWT token |

### Data Core (Port 8082)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/storage/encrypt` | Upload & encrypt video |
| GET | `/storage/{key}` | Download encrypted video |
| GET | `/quota/usage` | Get quota statistics |

### Stream Processing (Port 8083)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/cameras` | List cameras |
| POST | `/cameras` | Add camera |
| GET | `/blue-flow/events` | Get AI detections |
| GET | `/blue-flow/quota` | Get quota usage |

### Middleware (Port 8084) - Future
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/sentinel/alerts` | Get anomaly alerts |
| POST | `/sentinel/rules` | Create alert rule |

---

## 🔐 Default Credentials

### MySQL
- Host: `localhost:3306`
- User: `root`
- Password: `rootpassword`
- Databases: `eyeo_identity`, `eyeo_stream`

### PostgreSQL (Middleware)
- Host: `localhost:5432`
- User: `postgres`
- Password: `postgrespassword`
- Database: `eyeo_middleware`

### Test User (After Registration)
- Username: `testuser`
- Email: `test@eyeo.com`
- Password: `Test1234!`
- Tier: `FREE` (14-day trial)

---

## 🎓 Learning Path

1. **Backend Only** (30 min)
   - Start Identity + Data Core services
   - Test APIs with Postman/cURL
   - Check database changes

2. **Frontend Only** (20 min)
   - Start frontend with mock data
   - Explore Dashboard UI
   - Test i18n (EN/JA toggle)

3. **Full Stack** (45 min)
   - Start all services
   - Complete registration flow
   - Upload test video
   - Test quota enforcement

4. **Advanced** (60 min)
   - Add real camera (RTSP)
   - Configure YOLOv8 detection
   - Implement Stripe billing
   - Deploy to Azure

---

## 📦 Next Steps

### Phase 2.5: Billing Integration
```bash
# Add Stripe SDK
cd billing-service
mvn dependency:add -Dartifact=com.stripe:stripe-java:24.0.0

# Create billing service
mkdir -p billing-service/src/main/java/com/eyeo/billing
# ... implement Stripe checkout, webhooks, subscription management
```

### Phase 3: Production Deployment
```bash
# Build Docker images
docker build -t eyeo-identity:latest ./identity-service
docker build -t eyeo-data-core:latest ./data-core
docker build -t eyeo-frontend:latest ./frontend

# Push to Azure Container Registry
az acr login --name eyeoregistry
docker push eyeoregistry.azurecr.io/eyeo-identity:latest

# Deploy to Azure Container Apps
az containerapp create --name eyeo-identity ...
```

---

## 🆘 Support

### Documentation
- [Backend Implementation](./MONETIZATION_IMPLEMENTATION.md)
- [Frontend Implementation](./FRONTEND_IMPLEMENTATION.md)
- [API Testing Guide](../API_TESTING_GUIDE.md)

### Community
- GitHub Issues: [eyeo-platform/issues](https://github.com/user/eyeo-platform/issues)
- Discord: [Join Server](https://discord.gg/eyeo)
- Email: support@eyeo.com

---

**Happy Building! 🚀**
