# Image Inverter REST API

This document describes the REST API endpoints for the Image Inverter application.

## Overview

The Image Inverter API provides RESTful endpoints to invert images and retrieve information about processing operations. The API follows REST conventions and supports multiple response formats (JSON, XML, and binary image data).

**API Base URL:** `http://localhost:8080/api/images`

## Endpoints

### 1. Invert Image (Binary Response)
Returns the inverted image as PNG binary data.

```
POST /api/images/invert
```

**Request:**
- **Method:** POST
- **Content-Type:** multipart/form-data
- **Body Parameter:**
  - `file` (required): The image file to invert (PNG, JPEG, etc.)

**Response:**
- **Status:** 200 OK
- **Content-Type:** image/png
- **Body:** Binary PNG image data
- **Headers:**
  - `X-Processing-Time-Ms`: Time taken to process the image

**Example (cURL):**
```bash
curl -X POST -F "file=@myimage.png" http://localhost:8080/api/images/invert --output inverted.png
```

**Example (JavaScript/Fetch):**
```javascript
const formData = new FormData();
formData.append('file', imageFile);

fetch('http://localhost:8080/api/images/invert', {
    method: 'POST',
    body: formData
})
.then(response => response.blob())
.then(blob => {
    // Handle binary image data
    const url = window.URL.createObjectURL(blob);
    const img = document.createElement('img');
    img.src = url;
});
```

### 2. Invert Image (JSON Response)
Returns the inverted image as base64-encoded data in a JSON response wrapper.

```
POST /api/images/invert/json
```

**Request:**
- **Method:** POST
- **Content-Type:** multipart/form-data
- **Body Parameter:**
  - `file` (required): The image file to invert

**Response:**
- **Status:** 200 OK
- **Content-Type:** application/json
- **Body:**
```json
{
  "success": true,
  "message": "Image processed successfully",
  "data": {
    "status": "success",
    "message": "Image inverted successfully",
    "image_base64": "iVBORw0KGgoAAAANSUhEUgAAAAEA...",
    "format": "PNG",
    "size_bytes": 12345,
    "processing_time_ms": 45
  },
  "timestamp": 1703001234567
}
```

**Response Fields:**
- `success`: Boolean indicating if the operation was successful
- `message`: Human-readable message
- `data.image_base64`: Base64-encoded image data
- `data.format`: Image format (PNG, JPEG, etc.)
- `data.size_bytes`: Size of the output image in bytes
- `data.processing_time_ms`: Time taken to process in milliseconds
- `timestamp`: Unix timestamp of the response

**Example (cURL):**
```bash
curl -X POST -F "file=@myimage.png" http://localhost:8080/api/images/invert/json | jq
```

**Example (JavaScript/Fetch):**
```javascript
const formData = new FormData();
formData.append('file', imageFile);

fetch('http://localhost:8080/api/images/invert/json', {
    method: 'POST',
    body: formData
})
.then(response => response.json())
.then(data => {
    if (data.success) {
        const imageData = data.data.image_base64;
        const img = document.createElement('img');
        img.src = 'data:image/png;base64,' + imageData;
    }
});
```

### 3. Invert Image (XML Response)
Returns the inverted image in an XML response format.

```
POST /api/images/invert/xml
```

**Request:**
- **Method:** POST
- **Content-Type:** multipart/form-data
- **Body Parameter:**
  - `file` (required): The image file to invert

**Response:**
- **Status:** 200 OK
- **Content-Type:** application/xml
- **Body:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApiResponse>
    <success>true</success>
    <message>Image processed successfully</message>
    <data>
        <status>success</status>
        <message>Image inverted successfully</message>
        <imageBase64>iVBORw0KGgoAAAANSUhEUgAAAAEA...</imageBase64>
        <format>PNG</format>
        <sizeBytes>12345</sizeBytes>
        <processingTimeMs>45</processingTimeMs>
    </data>
    <timestamp>1703001234567</timestamp>
</ApiResponse>
```

**Example (cURL):**
```bash
curl -X POST -F "file=@myimage.png" http://localhost:8080/api/images/invert/xml
```

### 4. Health Check
Verify that the API is running and operational.

```
GET /api/images/health
```

**Request:**
- **Method:** GET

**Response:**
- **Status:** 200 OK
- **Content-Type:** application/json
- **Body:**
```json
{
  "success": true,
  "message": "Image Inverter API is running",
  "data": "OK",
  "timestamp": 1703001234567
}
```

**Example (cURL):**
```bash
curl http://localhost:8080/api/images/health
```

### 5. API Information
Get information about available API endpoints and version.

```
GET /api/images/info
```

**Request:**
- **Method:** GET

**Response:**
- **Status:** 200 OK
- **Content-Type:** application/json
- **Body:**
```json
{
  "success": true,
  "message": "API Information",
  "data": {
    "service": "Image Inverter API",
    "version": "1.0.0",
    "endpoints": [
      "POST /api/images/invert - Returns PNG binary",
      "POST /api/images/invert/json - Returns JSON response",
      "POST /api/images/invert/xml - Returns XML response",
      "GET /api/images/health - Health check",
      "GET /api/images/info - API information"
    ]
  },
  "timestamp": 1703001234567
}
```

**Example (cURL):**
```bash
curl http://localhost:8080/api/images/info
```

## Error Responses

The API returns appropriate HTTP status codes and error messages:

### 400 Bad Request
```json
{
  "success": false,
  "message": "Invalid argument: Image file is required",
  "data": null,
  "timestamp": 1703001234567
}
```

### 413 Payload Too Large
```json
{
  "success": false,
  "message": "File upload size exceeds limit",
  "data": null,
  "timestamp": 1703001234567
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "message": "An error occurred: Image processing failed",
  "data": null,
  "timestamp": 1703001234567
}
```

## Common HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200  | OK - Request successful |
| 400  | Bad Request - Invalid parameters |
| 413  | Payload Too Large - File too big |
| 500  | Internal Server Error - Server error |

## Content Negotiation

The API supports content negotiation. You can specify the desired format using:

1. **Path Extension:**
   ```
   POST /api/images/invert.json
   POST /api/images/invert.xml
   ```

2. **Accept Header:**
   ```bash
   curl -X POST -H "Accept: application/json" -F "file=@image.png" http://localhost:8080/api/images/invert
   curl -X POST -H "Accept: application/xml" -F "file=@image.png" http://localhost:8080/api/images/invert
   ```

## CORS Support

The API has CORS enabled for all origins, allowing cross-origin requests from web applications.

## Starting the Server

To start the Image Inverter API server:

```bash
# Using Maven
mvn spring-boot:run

# Using JAR
java -jar target/image-inverter-project-1.0-SNAPSHOT.jar

# The server will start on http://localhost:8080
```

## Architecture

The API follows a layered architecture similar to the JBoss helloworld-rs quickstart:

```
Controller Layer (ImageController)
     ↓
Service Layer (ImageService)
     ↓
Processor Layer (ImageProcessor)
     ↓
Image Data
```

Each layer has clear responsibilities:
- **Controllers:** Handle HTTP requests/responses
- **Services:** Business logic and orchestration
- **Processors:** Image manipulation operations
- **DTOs:** Data transfer objects for serialization

## Related Files

- **Controllers:** `src/main/java/backend/controllers/ImageController.java`
- **DTOs:** `src/main/java/backend/dto/`
- **Services:** `src/main/java/backend/services/ImageService.java`
- **Configuration:** `src/main/java/backend/config/`
