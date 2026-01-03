# TeraAPI Testing Guide

Complete guide for testing TeraAPI services using curl, Postman, and integration tests.

## Table of Contents
1. [Quick Start Testing](#quick-start-testing)
2. [cURL Examples](#curl-examples)
3. [Postman Collection](#postman-collection)
4. [Integration Tests](#integration-tests)
5. [Docker Testing](#docker-testing)
6. [Performance Testing](#performance-testing)

---

## Quick Start Testing

### Prerequisites
```bash
# Make sure services are running
# Option 1: Docker Compose
docker-compose -f docker/docker-compose.yml up

# Option 2: Local Java
# Terminal 1: IdentityService on port 8081
cd src/identity-service
mvn spring-boot:run

# Terminal 2: StreamProcessingService on port 8080
cd src/stream-processing-service
mvn spring-boot:run
```

### Health Check
```bash
# Check IdentityService health
curl http://localhost:8081/actuator/health

# Check StreamProcessingService health
curl http://localhost:8080/api/health
```

---

## cURL Examples

### 1. IdentityService - User Registration

**Endpoint**: `POST /api/auth/register`

```bash
curl -X POST http://localhost:8081/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "SecurePassword123!",
    "email": "test@example.com"
  }'
```

**Response** (Success - 201):
```json
{
  "id": 1,
  "username": "testuser",
  "email": "test@example.com",
  "roles": ["ROLE_USER"]
}
```

### 2. IdentityService - User Login

**Endpoint**: `POST /api/auth/login`

```bash
curl -X POST http://localhost:8081/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "SecurePassword123!"
  }'
```

**Response** (Success - 200):
```json
{
  "token": "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 86400,
  "type": "Bearer",
  "username": "testuser"
}
```

**Save token for next requests**:
```bash
TOKEN="eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9..."
```

### 3. IdentityService - Get Current User

**Endpoint**: `GET /api/auth/me`

```bash
curl -X GET http://localhost:8081/api/auth/me \
  -H "Authorization: Bearer $TOKEN"
```

**Response**:
```json
{
  "id": 1,
  "username": "testuser",
  "email": "test@example.com",
  "roles": ["ROLE_USER"]
}
```

### 4. StreamProcessingService - Validate Token

**Endpoint**: `POST /api/stream/validate-token`

```bash
curl -X POST http://localhost:8080/api/stream/validate-token \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "data": "test data"
  }'
```

**Response**:
```json
{
  "status": "valid",
  "username": "testuser",
  "expiresAt": "2026-01-03T14:30:00Z"
}
```

### 5. StreamProcessingService - Encrypt Data

**Endpoint**: `POST /api/stream/encrypt`

```bash
curl -X POST http://localhost:8080/api/stream/encrypt \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "plaintext": "sensitive data to encrypt",
    "licenseLevel": "FREE"
  }'
```

**Response**:
```json
{
  "ciphertext": "base64_encoded_encrypted_data",
  "algorithm": "AES-256-CBC",
  "timestamp": "2026-01-02T14:30:00Z"
}
```

### 6. StreamProcessingService - Decrypt Data

**Endpoint**: `POST /api/stream/decrypt`

```bash
curl -X POST http://localhost:8080/api/stream/decrypt \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "ciphertext": "base64_encoded_encrypted_data",
    "licenseLevel": "FREE"
  }'
```

**Response**:
```json
{
  "plaintext": "sensitive data to encrypt",
  "algorithm": "AES-256-CBC",
  "timestamp": "2026-01-02T14:30:00Z"
}
```

### 7. StreamProcessingService - License Check

**Endpoint**: `GET /api/stream/license-info`

```bash
curl -X GET http://localhost:8080/api/stream/license-info \
  -H "Authorization: Bearer $TOKEN"
```

**Response**:
```json
{
  "tier": "FREE",
  "maxDataSize": 1048576,
  "features": ["basic_encryption", "token_validation"],
  "requestsPerMinute": 60
}
```

---

## Postman Collection

### Import Collection

Create a file named `teraapi-postman.json`:

```json
{
  "info": {
    "name": "TeraAPI",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Identity Service",
      "item": [
        {
          "name": "Register User",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\"username\": \"testuser\", \"password\": \"SecurePassword123!\", \"email\": \"test@example.com\"}"
            },
            "url": {
              "raw": "http://localhost:8081/api/auth/register",
              "protocol": "http",
              "host": ["localhost"],
              "port": "8081",
              "path": ["api", "auth", "register"]
            }
          }
        },
        {
          "name": "Login User",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\"username\": \"testuser\", \"password\": \"SecurePassword123!\"}"
            },
            "url": {
              "raw": "http://localhost:8081/api/auth/login",
              "protocol": "http",
              "host": ["localhost"],
              "port": "8081",
              "path": ["api", "auth", "login"]
            }
          }
        },
        {
          "name": "Get Current User",
          "request": {
            "method": "GET",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{token}}"
              }
            ],
            "url": {
              "raw": "http://localhost:8081/api/auth/me",
              "protocol": "http",
              "host": ["localhost"],
              "port": "8081",
              "path": ["api", "auth", "me"]
            }
          }
        }
      ]
    },
    {
      "name": "Stream Processing Service",
      "item": [
        {
          "name": "Encrypt Data",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              },
              {
                "key": "Authorization",
                "value": "Bearer {{token}}"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\"plaintext\": \"sensitive data\", \"licenseLevel\": \"FREE\"}"
            },
            "url": {
              "raw": "http://localhost:8080/api/stream/encrypt",
              "protocol": "http",
              "host": ["localhost"],
              "port": "8080",
              "path": ["api", "stream", "encrypt"]
            }
          }
        },
        {
          "name": "Decrypt Data",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              },
              {
                "key": "Authorization",
                "value": "Bearer {{token}}"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\"ciphertext\": \"base64_ciphertext\", \"licenseLevel\": \"FREE\"}"
            },
            "url": {
              "raw": "http://localhost:8080/api/stream/decrypt",
              "protocol": "http",
              "host": ["localhost"],
              "port": "8080",
              "path": ["api", "stream", "decrypt"]
            }
          }
        },
        {
          "name": "Validate Token",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              },
              {
                "key": "Authorization",
                "value": "Bearer {{token}}"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\"data\": \"test\"}"
            },
            "url": {
              "raw": "http://localhost:8080/api/stream/validate-token",
              "protocol": "http",
              "host": ["localhost"],
              "port": "8080",
              "path": ["api", "stream", "validate-token"]
            }
          }
        }
      ]
    }
  ]
}
```

**Steps to use in Postman**:
1. Open Postman
2. Click "Import" → "Paste Raw Text"
3. Copy the JSON above and paste
4. Click "Import"
5. Set `{{token}}` variable in Postman environment

---

## Integration Tests

### Run All Tests

```bash
# Identity Service Tests
cd src/identity-service
mvn test

# Stream Processing Service Tests
cd src/stream-processing-service
mvn test

# All Tests
mvn test -DskipITs=false
```

### Example Integration Test

```java
@SpringBootTest
@AutoConfigureMockMvc
public class AuthControllerIntegrationTest {
    
    @Autowired
    private MockMvc mockMvc;
    
    @Test
    public void testUserRegistrationAndLogin() throws Exception {
        // Register user
        mockMvc.perform(post("/api/auth/register")
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"username\":\"test\",\"password\":\"pass123\",\"email\":\"test@test.com\"}"))
            .andExpect(status().isCreated());
        
        // Login
        MvcResult result = mockMvc.perform(post("/api/auth/login")
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"username\":\"test\",\"password\":\"pass123\"}"))
            .andExpect(status().isOk())
            .andReturn();
    }
}
```

---

## Docker Testing

### Start Services with Docker

```bash
# Build and start
docker-compose -f docker/docker-compose.yml up --build

# Run in background
docker-compose -f docker/docker-compose.yml up -d

# View logs
docker-compose -f docker/docker-compose.yml logs -f

# Stop services
docker-compose -f docker/docker-compose.yml down
```

### Test Docker Endpoints

```bash
# Wait for services to be healthy
sleep 10

# Test IdentityService
curl http://localhost:8081/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"docker","password":"test123","email":"docker@test.com"}'

# Test StreamProcessingService
curl http://localhost:8080/api/stream/license-info \
  -H "Authorization: Bearer $TOKEN"
```

---

## Performance Testing

### Load Testing with Apache JMeter

Create a test plan:
```jmeter
1. Add Thread Group (100 users, 5 second ramp-up)
2. Add HTTP Samplers:
   - POST /api/auth/login (IdentityService)
   - POST /api/stream/encrypt (StreamProcessingService)
3. Add listeners for results
```

### Simple Load Test with curl

```bash
#!/bin/bash
# Load test script

USERS=10
REQUESTS=100

for i in $(seq 1 $USERS); do
  for j in $(seq 1 $REQUESTS); do
    curl -X GET http://localhost:8080/api/stream/license-info \
      -H "Authorization: Bearer $TOKEN" &
  done
done
wait

echo "Load test complete"
```

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Connection refused | Services not running - start with docker-compose |
| 401 Unauthorized | JWT token invalid or expired - login again |
| 403 Forbidden | License tier doesn't support operation |
| CORS error | Add origin headers or configure CORS in services |
| Port already in use | Change ports or kill existing process |

### Debug Logs

```bash
# Enable debug logging
export DEBUG=true

# Docker logs
docker-compose -f docker/docker-compose.yml logs -f identity

# Maven test logs
mvn test -X

# Java application logs
tail -f logs/application.log
```

---

*Last Updated: January 2026*
