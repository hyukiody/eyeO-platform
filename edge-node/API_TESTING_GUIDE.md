# Image Inverter API Testing Guide

Complete guide for testing the Image Inverter REST API using curl, Postman, and integration tests.

## Table of Contents
1. [Quick Start](#quick-start)
2. [cURL Examples](#curl-examples)
3. [Postman Collection](#postman-collection)
4. [Integration Tests](#integration-tests)
5. [Testing Strategies](#testing-strategies)
6. [Performance Testing](#performance-testing)

---

## Quick Start

### Prerequisites

```bash
# Java 17+ required
java -version

# Maven 3.6+ required
mvn -version
```

### Start the Server

```bash
# Option 1: Run with Maven
mvn spring-boot:run

# Option 2: Build and run JAR
mvn clean package
java -jar target/image-inverter-*.jar
```

Server will start on `http://localhost:8080`

### Health Check

```bash
curl http://localhost:8080/api/images/health
```

Expected response:
```json
{
  "status": "UP",
  "timestamp": "2026-01-02T14:30:00Z"
}
```

---

## cURL Examples

### 1. Health Check

**Endpoint**: `GET /api/images/health`

```bash
curl -i http://localhost:8080/api/images/health
```

**Response** (200 OK):
```json
{
  "status": "UP",
  "timestamp": "2026-01-02T14:30:00Z"
}
```

### 2. Info Endpoint

**Endpoint**: `GET /api/images/info`

```bash
curl http://localhost:8080/api/images/info
```

**Response** (200 OK):
```json
{
  "name": "Image Inverter API",
  "version": "1.0.0",
  "description": "REST API for inverting images",
  "endpoints": {
    "health": "GET /api/images/health",
    "info": "GET /api/images/info",
    "invert": "POST /api/images/invert"
  }
}
```

### 3. Invert Image (JSON Request)

**Endpoint**: `POST /api/images/invert`

**With JSON body**:
```bash
# Create a test PNG and convert to base64
python3 -c "
import base64
with open('test.png', 'rb') as f:
    data = base64.b64encode(f.read()).decode()
print(data)
" > image_base64.txt

curl -X POST http://localhost:8080/api/images/invert \
  -H "Content-Type: application/json" \
  -d @- << EOF
{
  "imageData": "$(cat image_base64.txt)",
  "format": "png"
}
EOF
```

**Response** (200 OK):
```json
{
  "imageData": "base64_encoded_inverted_image",
  "originalSize": 2048,
  "processedSize": 2050,
  "processingTime": 45,
  "format": "png"
}
```

### 4. Invert Image (Binary Request)

**Endpoint**: `POST /api/images/invert`

**With binary PNG data**:
```bash
curl -X POST http://localhost:8080/api/images/invert \
  -H "Content-Type: image/png" \
  --data-binary @test.png \
  --output inverted.png
```

**Response**: Binary PNG data (inverted image)

### 5. Batch Image Inversion (Multiple Images)

```bash
# Create multiple test images
for i in {1..3}; do
  convert -size 100x100 xc:red test_$i.png
done

# Process each
for img in test_*.png; do
  curl -X POST http://localhost:8080/api/images/invert \
    -H "Content-Type: image/png" \
    --data-binary @"$img" \
    --output "inverted_$img"
  echo "Processed: $img"
done
```

---

## Postman Collection

### Create Postman Environment

**File**: `teraapi-environment.json`

```json
{
  "name": "Image Inverter",
  "values": [
    {
      "key": "base_url",
      "value": "http://localhost:8080",
      "enabled": true
    },
    {
      "key": "image_base64",
      "value": "",
      "enabled": true
    }
  ]
}
```

### Postman Collection

**File**: `image-inverter-postman.json`

```json
{
  "info": {
    "name": "Image Inverter API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Health & Info",
      "item": [
        {
          "name": "Health Check",
          "request": {
            "method": "GET",
            "url": "{{base_url}}/api/images/health"
          }
        },
        {
          "name": "API Info",
          "request": {
            "method": "GET",
            "url": "{{base_url}}/api/images/info"
          }
        }
      ]
    },
    {
      "name": "Image Operations",
      "item": [
        {
          "name": "Invert Image (JSON)",
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
              "raw": "{\"imageData\": \"{{image_base64}}\", \"format\": \"png\"}"
            },
            "url": "{{base_url}}/api/images/invert"
          }
        },
        {
          "name": "Invert Image (Binary)",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "image/png"
              }
            ],
            "body": {
              "mode": "file",
              "file": "test.png"
            },
            "url": "{{base_url}}/api/images/invert"
          }
        }
      ]
    }
  ]
}
```

**Steps to use in Postman**:
1. Import `teraapi-environment.json` as environment
2. Import `image-inverter-postman.json` as collection
3. Select "Image Inverter" environment
4. Run requests from the collection

---

## Integration Tests

### Run Tests

```bash
# Run all tests
mvn test

# Run specific test class
mvn test -Dtest=ImageInverterControllerTest

# Run with coverage
mvn test jacoco:report

# View coverage report
open target/site/jacoco/index.html
```

### Example Integration Tests

```java
@SpringBootTest
@AutoConfigureMockMvc
public class ImageInverterControllerTest {
    
    @Autowired
    private MockMvc mockMvc;
    
    @Test
    public void testHealthEndpoint() throws Exception {
        mockMvc.perform(get("/api/images/health"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("UP"));
    }
    
    @Test
    public void testInfoEndpoint() throws Exception {
        mockMvc.perform(get("/api/images/info"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.name").value("Image Inverter API"));
    }
    
    @Test
    public void testInvertImageWithJsonBody() throws Exception {
        // Create test image data
        String testImage = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk...";
        
        mockMvc.perform(post("/api/images/invert")
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"imageData\":\"" + testImage + "\",\"format\":\"png\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.format").value("png"));
    }
    
    @Test
    public void testInvertImageWithBinaryData() throws Exception {
        // Get test image bytes
        byte[] testImageBytes = getTestImageBytes();
        
        mockMvc.perform(post("/api/images/invert")
            .contentType(MediaType.IMAGE_PNG)
            .content(testImageBytes))
            .andExpect(status().isOk());
    }
    
    @Test
    public void testErrorHandling() throws Exception {
        // Test invalid image data
        mockMvc.perform(post("/api/images/invert")
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"imageData\":\"invalid\",\"format\":\"png\"}"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.error").exists());
    }
    
    @Test
    public void testCorsHeaders() throws Exception {
        mockMvc.perform(get("/api/images/health")
            .header("Origin", "http://example.com"))
            .andExpect(status().isOk())
            .andExpect(header().exists("Access-Control-Allow-Origin"));
    }
    
    private byte[] getTestImageBytes() {
        // Generate simple test image (1x1 red pixel PNG)
        return new byte[]{/* PNG bytes */};
    }
}
```

---

## Testing Strategies

### Unit Testing

```bash
# Test service layer
mvn test -Dtest=ImageInversionServiceTest
```

### Integration Testing

```bash
# Test full request-response cycle
mvn verify -DskipUnitTests=false
```

### End-to-End Testing

```bash
# Start server
mvn spring-boot:run &

# Run smoke tests
sleep 5
curl http://localhost:8080/api/images/health

# Kill server
pkill -f spring-boot
```

### Test Coverage

```bash
# Generate coverage report
mvn clean test jacoco:report

# View report
open target/site/jacoco/index.html  # macOS
xdg-open target/site/jacoco/index.html  # Linux
start target/site/jacoco/index.html  # Windows
```

---

## Performance Testing

### Load Testing Script

```bash
#!/bin/bash
# load-test.sh

SERVER_URL="http://localhost:8080"
DURATION=60
CONCURRENT_USERS=10

echo "Starting load test for $DURATION seconds..."
echo "Users: $CONCURRENT_USERS"
echo "Target: $SERVER_URL/api/images/health"

start_time=$(date +%s)
requests=0

for ((i=0; i<CONCURRENT_USERS; i++)); do
  (
    while [ $(($(date +%s) - start_time)) -lt $DURATION ]; do
      curl -s "$SERVER_URL/api/images/health" > /dev/null
      ((requests++))
    done
  ) &
done

wait

end_time=$(date +%s)
elapsed=$((end_time - start_time))

echo "Test complete!"
echo "Duration: ${elapsed}s"
echo "Total requests: $requests"
echo "Requests/sec: $((requests / elapsed))"
```

**Run test**:
```bash
chmod +x load-test.sh
./load-test.sh
```

### Apache JMeter Test Plan

1. Open JMeter
2. Create Thread Group:
   - Number of Threads: 50
   - Ramp-up Time: 10s
   - Loop Count: 10

3. Add HTTP Request Sampler:
   - Protocol: HTTP
   - Server: localhost
   - Port: 8080
   - Path: /api/images/health

4. Add listeners for results analysis

---

## Common Test Scenarios

### Scenario 1: Basic Health Check
```bash
for i in {1..10}; do
  curl -w "\nHTTP Status: %{http_code}\nTime: %{time_total}s\n" \
    http://localhost:8080/api/images/health
done
```

### Scenario 2: Image Inversion Workflow
```bash
# 1. Check health
curl http://localhost:8080/api/images/health

# 2. Get info
curl http://localhost:8080/api/images/info

# 3. Invert image
curl -X POST http://localhost:8080/api/images/invert \
  -H "Content-Type: image/png" \
  --data-binary @test.png \
  --output result.png

echo "Done!"
```

### Scenario 3: Error Handling
```bash
# Test with invalid data
curl -X POST http://localhost:8080/api/images/invert \
  -H "Content-Type: application/json" \
  -d '{"imageData":"invalid","format":"png"}' \
  -w "\nStatus: %{http_code}\n"

# Test with unsupported format
curl -X POST http://localhost:8080/api/images/invert \
  -H "Content-Type: application/json" \
  -d '{"imageData":"...","format":"xyz"}' \
  -w "\nStatus: %{http_code}\n"
```

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Connection refused | Start server: `mvn spring-boot:run` |
| 404 Not Found | Check endpoint path spelling |
| 415 Unsupported Media Type | Check Content-Type header |
| 500 Internal Error | Check server logs and image format |
| Timeout | Image too large or processing slow |

### Debug Mode

```bash
# Enable debug logging
export SPRING_PROFILES_ACTIVE=debug
mvn spring-boot:run

# Check logs
tail -f logs/spring.log
```

---

*Last Updated: January 2026*
*Version: 1.0*
