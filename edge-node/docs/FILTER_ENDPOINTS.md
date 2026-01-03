# New Image-Inverter Endpoints

## Batch & Filter Operations

### POST /api/images/batch-process
Process multiple images in parallel

**Request (multipart/form-data):**
```
files: [file1.jpg, file2.png, ...]
operation: "grayscale" | "blur" | "brightness" | "contrast" | "sharpen"
params: {"radius": 5}  // optional
```

**Response:**
```json
{
  "totalImages": 3,
  "successful": 3,
  "failed": 0,
  "results": [
    {
      "filename": "file1.jpg",
      "success": true,
      "processingTimeMs": 145
    }
  ],
  "totalProcessingTimeMs": 420
}
```

### POST /api/images/filter/grayscale
Convert image to grayscale

**Request (multipart/form-data):**
```
file: image.jpg
```

**Response:** Processed image (image/jpeg)

### POST /api/images/filter/blur
Apply blur filter

**Request (multipart/form-data):**
```
file: image.jpg
radius: 5  // default
```

**Response:** Processed image (image/jpeg)

### POST /api/images/filter/brightness
Adjust brightness

**Request (multipart/form-data):**
```
file: image.jpg
factor: 1.2  // 0.5-2.0, default 1.0
```

**Response:** Processed image (image/jpeg)

### POST /api/images/filter/contrast
Adjust contrast

**Request (multipart/form-data):**
```
file: image.jpg
factor: 1.3  // default 1.0
```

**Response:** Processed image (image/jpeg)

### POST /api/images/filter/sharpen
Apply sharpen filter

**Request (multipart/form-data):**
```
file: image.jpg
```

**Response:** Processed image (image/jpeg)

### GET /api/images/filters
Get available filters list

**Response:**
```json
{
  "filters": [
    {
      "name": "grayscale",
      "description": "Convert to grayscale",
      "parameters": []
    },
    {
      "name": "blur",
      "description": "Gaussian blur",
      "parameters": [{"name": "radius", "type": "integer", "default": 5}]
    }
  ]
}
```
