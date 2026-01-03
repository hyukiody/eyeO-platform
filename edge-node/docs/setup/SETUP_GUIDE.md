# Image Inverter REST API - Setup & Implementation Guide

## Summary of Changes

This document outlines all the changes made to set up a REST API for the Image Inverter project, following the architectural patterns from the JBoss helloworld-rs quickstart.

## What Was Added

### 1. **DTO (Data Transfer Objects)** - `backend/dto/`

#### `ApiResponse.java`
Generic response wrapper providing consistent API responses across all endpoints.

**Features:**
- `success`: Boolean status
- `message`: Human-readable message
- `data`: Generic payload
- `timestamp`: Response timestamp

**Usage:**
```java
new ApiResponse<>(true, "Success message", data)
```

---

#### `ImageInvertResponse.java`
Specialized response for image inversion operations.

**Features:**
- Status and message
- Base64-encoded image data
- Image format (PNG, JPEG, etc.)
- File size in bytes
- Processing time in milliseconds

---

#### `ImageInfoResponse.java`
Response for image metadata/info endpoints (extensible for future use).

---

### 2. **Enhanced REST Controller** - `backend/controllers/ImageController.java`

**New Endpoints:**

1. **POST `/api/images/invert`** (original, enhanced)
   - Returns PNG binary data
   - Includes `X-Processing-Time-Ms` header
   - Similar to helloworld-rs `/rest/xml`

2. **POST `/api/images/invert/json`** (new)
   - Returns JSON with base64-encoded image
   - Includes metadata and processing time
   - Similar to helloworld-rs `/rest/json`

3. **POST `/api/images/invert/xml`** (new)
   - Returns XML-formatted response
   - Same structure as JSON but in XML
   - Demonstrates content negotiation

4. **GET `/api/images/health`** (new)
   - Health check endpoint
   - Returns API status
   - Useful for load balancers and monitoring

5. **GET `/api/images/info`** (new)
   - API information endpoint
   - Lists available endpoints
   - Returns version and service info

**CORS Support:**
- `@CrossOrigin(origins = "*")` enabled globally
- Allows cross-origin requests from web applications

---

### 3. **Configuration Classes** - `backend/config/`

#### `RestApiConfiguration.java`
Configures content negotiation for multiple response formats.

**Features:**
- JSON default format
- XML support via `.xml` extension
- Image format support
- Path extension-based negotiation

#### `GlobalExceptionHandler.java`
Centralized exception handling for all REST endpoints.

**Handles:**
- `MaxUploadSizeExceededException` → 413 Payload Too Large
- `IllegalArgumentException` → 400 Bad Request
- Generic `Exception` → 500 Internal Server Error

All errors return consistent `ApiResponse` format.

---

### 4. **Dependencies** - Updated `pom.xml`

**New Dependencies Added:**

```xml
<!-- XML Support -->
<dependency>
    <groupId>com.fasterxml.jackson.dataformat</groupId>
    <artifactId>jackson-dataformat-xml</artifactId>
</dependency>

<!-- Monitoring & Health Checks -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

These enable:
- XML serialization/deserialization
- `/actuator/health` endpoint
- Monitoring and metrics

---

### 5. **Testing & Documentation**

#### `test-api.sh` (Linux/Mac)
Bash script to test all REST endpoints using curl.

#### `test-api.bat` (Windows)
Batch script for Windows users.

#### `REST_API.md`
Comprehensive API documentation including:
- All endpoint descriptions
- Request/response examples
- cURL examples
- JavaScript/Fetch examples
- Error codes and status codes
- Content negotiation guide
- Architecture overview

#### `backend/client/RestApiTestClient.java`
Java client for testing endpoints programmatically.

---

## Architecture Comparison

### helloworld-rs (JBoss EAP)
```
HTTP Request
    ↓
JAX-RS Resource (@Path, @GET, @POST)
    ↓
Response (XML/JSON)
```

### Image Inverter (Spring Boot)
```
HTTP Request
    ↓
@RestController (ImageController)
    ↓
@Service (ImageService)
    ↓
@Component (ImageProcessor)
    ↓
Response (JSON/XML/Binary)
```

Both follow REST principles and support multiple response formats.

---

## How to Use the New REST API

### 1. Start the Server
```bash
mvn spring-boot:run
```
Server runs on `http://localhost:8080`

### 2. Test Endpoints

#### Health Check
```bash
curl http://localhost:8080/api/images/health
```

#### Invert Image (Binary)
```bash
curl -X POST -F "file=@myimage.png" \
  http://localhost:8080/api/images/invert \
  --output inverted.png
```

#### Invert Image (JSON)
```bash
curl -X POST -F "file=@myimage.png" \
  http://localhost:8080/api/images/invert/json | jq
```

#### Invert Image (XML)
```bash
curl -X POST -F "file=@myimage.png" \
  http://localhost:8080/api/images/invert/xml
```

### 3. Using Test Scripts
```bash
# Linux/Mac
bash test-api.sh

# Windows
test-api.bat
```

### 4. Programmatic Usage

**JavaScript/Fetch:**
```javascript
const formData = new FormData();
formData.append('file', imageFile);

const response = await fetch(
  'http://localhost:8080/api/images/invert/json',
  { method: 'POST', body: formData }
);
const data = await response.json();
```

**Java Client:**
```bash
mvn exec:java -Dexec.mainClass="backend.client.RestApiTestClient"
```

---

## Response Format Examples

### Success Response (JSON)
```json
{
  "success": true,
  "message": "Image processed successfully",
  "data": {
    "status": "success",
    "message": "Image inverted successfully",
    "image_base64": "iVBORw0KGgo...",
    "format": "PNG",
    "size_bytes": 12345,
    "processing_time_ms": 45
  },
  "timestamp": 1703001234567
}
```

### Error Response (JSON)
```json
{
  "success": false,
  "message": "File upload size exceeds limit",
  "data": null,
  "timestamp": 1703001234567
}
```

### XML Response
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApiResponse>
    <success>true</success>
    <message>Image processed successfully</message>
    <data>
        <status>success</status>
        <imageBase64>iVBORw0KGgo...</imageBase64>
        <format>PNG</format>
        <sizeBytes>12345</sizeBytes>
        <processingTimeMs>45</processingTimeMs>
    </data>
    <timestamp>1703001234567</timestamp>
</ApiResponse>
```

---

## Content Negotiation

The API supports multiple formats via content negotiation:

### Method 1: Path Extension
```bash
curl http://localhost:8080/api/images/info.json
curl http://localhost:8080/api/images/info.xml
```

### Method 2: Accept Header
```bash
curl -H "Accept: application/json" http://localhost:8080/api/images/info
curl -H "Accept: application/xml" http://localhost:8080/api/images/info
```

---

## Integration Points

### For Web Frontend
- Use `/api/images/invert/json` endpoint
- Get base64-encoded image in response
- Display using `<img src="data:image/png;base64,..." />`

### For Mobile Apps
- Use `/api/images/invert` endpoint
- Get binary image data directly
- Save to device storage

### For Enterprise Systems
- Use `/api/images/invert/xml` endpoint
- Integrate with SOAP/XML-based systems
- Use standard XML parsers

---

## Extending the API

### Adding a New Endpoint

1. **Create DTO** (if needed):
```java
public class NewResponseDto {
    private String field;
    // getters/setters
}
```

2. **Add Controller Method**:
```java
@GetMapping("/new-endpoint")
public ResponseEntity<ApiResponse<NewResponseDto>> newEndpoint() {
    NewResponseDto data = new NewResponseDto();
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Success", data)
    );
}
```

3. **Test**:
```bash
curl http://localhost:8080/api/images/new-endpoint
```

### Adding New Image Operations

1. Add method to `ImageProcessor`
2. Add service method to `ImageService`
3. Add controller endpoint to `ImageController`
4. Create corresponding DTO for response
5. Document in `REST_API.md`

---

## File Structure

```
Image-Inverter_Project/
├── src/main/java/backend/
│   ├── ImageInverterApplication.java
│   ├── controllers/
│   │   └── ImageController.java              [ENHANCED]
│   ├── services/
│   │   └── ImageService.java
│   ├── processor/
│   │   └── ImageProcessor.java
│   ├── dto/                                   [NEW]
│   │   ├── ApiResponse.java
│   │   ├── ImageInvertResponse.java
│   │   └── ImageInfoResponse.java
│   ├── config/                                [NEW]
│   │   ├── RestApiConfiguration.java
│   │   └── GlobalExceptionHandler.java
│   ├── client/                                [NEW]
│   │   └── RestApiTestClient.java
│   └── [other packages...]
│
├── pom.xml                                    [UPDATED]
├── REST_API.md                                [NEW]
├── test-api.sh                                [NEW]
├── test-api.bat                               [NEW]
├── README.md                                  [UPDATED]
└── [other files...]
```

---

## Key Improvements Over Original

1. **Multiple Response Formats**: JSON, XML, and binary support
2. **Content Negotiation**: Flexible format selection
3. **Consistent Error Handling**: Global exception handler
4. **Metadata in Responses**: Processing time, file size, format info
5. **Health Monitoring**: Health check and info endpoints
6. **CORS Support**: Cross-origin request handling
7. **Comprehensive Documentation**: REST_API.md with examples
8. **Test Scripts**: Easy API testing for both Unix and Windows
9. **Scalable Architecture**: Easy to add new endpoints and formats

---

## Related Quickstarts

This implementation is inspired by:
- **JBoss helloworld-rs**: https://github.com/jboss-developer/jboss-eap-quickstarts/tree/7.4.x/helloworld-rs
- Uses similar patterns for multiple response formats
- Demonstrates REST best practices
- Shows how to structure REST APIs

---

## Troubleshooting

### Issue: API returning 404
- Ensure server is running: `mvn spring-boot:run`
- Check port: http://localhost:8080
- Verify endpoint path

### Issue: File upload fails
- Check file size against Spring Boot limits
- Ensure file format is supported
- Verify file path in curl command

### Issue: XML response not working
- Verify `jackson-dataformat-xml` is in pom.xml
- Check `RestApiConfiguration` is loaded
- Try with explicit `Accept: application/xml` header

### Issue: CORS errors
- Check `@CrossOrigin` annotation in controller
- Verify headers in request
- Check browser console for details

---

## Next Steps

1. **Test all endpoints** using `test-api.sh` or `test-api.bat`
2. **Integrate with frontend** using the JSON endpoints
3. **Add more operations** following the extension guide
4. **Deploy** to production using Docker or cloud platform
5. **Monitor** using health endpoints

---

## Questions?

Refer to:
- `REST_API.md` for endpoint documentation
- `ImageController.java` for implementation details
- `RestApiConfiguration.java` for configuration
- Test scripts for usage examples
