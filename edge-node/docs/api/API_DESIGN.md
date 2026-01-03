# REST API Architecture & Design

## Overview

The Image Inverter REST API is designed as an **Open Host Service (OHS)** following DDD principles, Clean Architecture layers, and REST best practices.

---

## 1. REST API as Open Host Service (OHS)

### Definition
```
OHS: ImageProcessingBC → REST API → Consumers
    Where: BC = Bounded Context
           → = Integration via API
```

### Consumers
- Web clients (JavaScript, React)
- Mobile apps
- Third-party services
- Desktop clients

---

## 2. Core API Endpoints

### 1.1 Image Inversion Endpoint

**Endpoint:** `POST /api/v1/images/invert`

**Purpose:** Invert image colors

**Request (DTO):**
```json
{
  "imageBase64": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
  "format": "PNG",
  "metadata": {
    "userId": "user-123",
    "priority": 1
  }
}
```

**Response (DTO):**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "status": "COMPLETED",
    "originalImageBase64": "iVBORw0KGgoAAAAN...",
    "invertedImageBase64": "iVBORw0KGgoAAAAN...",
    "processingTime_ms": 245,
    "timestamp": "2025-12-18T10:30:00Z"
  },
  "errors": []
}
```

**Java Implementation:**

```java
@RestController
@RequestMapping("/api/v1/images")
public class ImageController {
    
    private final ImageService imageService;
    private final DTOConverter converter;
    
    @PostMapping("/invert")
    public ResponseEntity<ApiResponse<ImageInvertResponse>> invertImage(
        @Valid @RequestBody ImageInvertRequest request
    ) {
        ImageInvertResponse response = imageService.invertImage(request);
        return ResponseEntity.ok(
            ApiResponse.success(response)
        );
    }
}
```

**Layer Mapping:**
```
HTTP Request
    ↓ [L₂ - Controller]
ImageInvertRequest (DTO)
    ↓ [ACL: DTO → Domain Entity]
ImageData (ValueObject)
    ↓ [L₁ - Application Service]
ImageService.invertImage()
    ↓ [L₀ - Domain Service]
ImageInversionService.invert()
    ↓ [L₃ - Framework]
AwtImageProcessor.invertPixels()
    ↓ [Result]
InversionResult (ValueObject)
    ↓ [L₁ - Repository]
Image (Entity) saved
    ↓ [ACL: Entity → Response DTO]
ImageInvertResponse
    ↓ [L₂ - Controller]
HTTP Response (JSON)
```

---

### 1.2 Get Image Endpoint

**Endpoint:** `GET /api/v1/images/{id}`

**Purpose:** Retrieve processed image

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "status": "COMPLETED",
    "originalImageBase64": "...",
    "invertedImageBase64": "...",
    "processingTime_ms": 245,
    "createdAt": "2025-12-18T10:25:00Z",
    "completedAt": "2025-12-18T10:25:00.245Z"
  },
  "errors": []
}
```

**Implementation:**
```java
@GetMapping("/{id}")
public ResponseEntity<ApiResponse<ImageDTO>> getImage(
    @PathVariable UUID id
) {
    Image image = imageService.getImage(id);
    return ResponseEntity.ok(
        ApiResponse.success(converter.toImageDTO(image))
    );
}
```

---

### 1.3 Get Processing Status Endpoint

**Endpoint:** `GET /api/v1/processing/{jobId}/status`

**Purpose:** Track processing progress

**Response:**
```json
{
  "success": true,
  "data": {
    "jobId": "550e8400-e29b-41d4-a716-446655440000",
    "imageId": "550e8400-e29b-41d4-a716-446655440001",
    "status": "PROCESSING",
    "progress": 45,
    "estimatedTime_ms": 200,
    "createdAt": "2025-12-18T10:25:00Z",
    "startedAt": "2025-12-18T10:25:01Z"
  },
  "errors": []
}
```

---

### 1.4 Statistics Endpoint

**Endpoint:** `GET /api/v1/statistics`

**Purpose:** Get processing metrics

**Query Parameters:**
- `timeRange`: `LAST_HOUR`, `LAST_DAY`, `LAST_WEEK`

**Response:**
```json
{
  "success": true,
  "data": {
    "totalProcessed": 1250,
    "successCount": 1223,
    "failureCount": 27,
    "successRate": 97.84,
    "avgProcessingTime_ms": 187.5,
    "p99ProcessingTime_ms": 450,
    "totalBytes": 52428800,
    "period": "LAST_DAY"
  },
  "errors": []
}
```

---

### 1.5 Delete Image Endpoint

**Endpoint:** `DELETE /api/v1/images/{id}`

**Purpose:** Remove processed image

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "deletedAt": "2025-12-18T10:30:00Z"
  },
  "errors": []
}
```

---

## 3. DTOs (Anti-Corruption Layer)

### Request DTOs

**Location:** `backend/dto/ImageInvertRequest.java`

```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImageInvertRequest {
    
    @NotBlank(message = "Image data is required")
    private String imageBase64;
    
    @NotNull(message = "Image format is required")
    @Pattern(regexp = "PNG|JPG|JPEG|BMP|GIF", 
             message = "Unsupported format")
    private String format;
    
    @Valid
    private MetadataRequest metadata;
    
    @Setter(AccessLevel.PRIVATE)
    private Instant createdAt;
    
    @PostConstruct
    private void init() {
        this.createdAt = Instant.now();
    }
}

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MetadataRequest {
    
    private String userId;
    
    @Min(1)
    @Max(10)
    private Integer priority = 5;
    
    private Map<String, String> tags;
}
```

### Response DTOs

**Location:** `backend/dto/ImageInvertResponse.java`

```java
@Data
@Builder
public class ImageInvertResponse {
    
    private UUID id;
    
    @JsonProperty("status")
    private String state;
    
    private String originalImageBase64;
    
    private String invertedImageBase64;
    
    @JsonProperty("processingTime_ms")
    private Long processingTimeMills;
    
    private String errorMessage;
    
    private Instant timestamp;
    
    public static ImageInvertResponse fromEntity(Image image) {
        return ImageInvertResponse.builder()
            .id(image.getId())
            .state(image.getState().name())
            .originalImageBase64(encodeBytes(
                image.getImageData().getPixels()
            ))
            .invertedImageBase64(
                image.getResult() != null 
                    ? encodeBytes(image.getResult().getInvertedPixels())
                    : null
            )
            .processingTimeMills(
                image.getResult() != null 
                    ? image.getResult().getProcessingTime_ms()
                    : null
            )
            .timestamp(image.getModifiedAt())
            .build();
    }
    
    private static String encodeBytes(byte[] bytes) {
        return Base64.getEncoder().encodeToString(bytes);
    }
}
```

### Generic Response Wrapper

**Location:** `backend/dto/ApiResponse.java`

```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ApiResponse<T> {
    
    private boolean success;
    private T data;
    private List<ErrorDetail> errors;
    private Map<String, Object> metadata;
    
    public static <T> ApiResponse<T> success(T data) {
        return ApiResponse.<T>builder()
            .success(true)
            .data(data)
            .errors(new ArrayList<>())
            .build();
    }
    
    public static <T> ApiResponse<T> error(
        String code,
        String message,
        int status
    ) {
        return ApiResponse.<T>builder()
            .success(false)
            .errors(List.of(new ErrorDetail(code, message, status)))
            .build();
    }
}

@Data
@AllArgsConstructor
public class ErrorDetail {
    private String code;
    private String message;
    private int status;
}
```

---

## 4. Error Handling

### Exception Hierarchy

```
RuntimeException
├── DomainException (Domain layer errors)
│   ├── InvalidImageException
│   ├── ProcessingException
│   └── ValidationException
└── ApplicationException (Application layer errors)
    ├── ImageNotFoundException
    ├── ConflictException
    └── InvalidRequestException
```

### Global Exception Handler

**Location:** `backend/config/GlobalExceptionHandler.java`

```java
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {
    
    @ExceptionHandler(ValidationException.class)
    public ResponseEntity<ApiResponse<?>> handleValidationException(
        ValidationException e
    ) {
        log.warn("Validation error: {}", e.getMessage());
        return ResponseEntity.badRequest().body(
            ApiResponse.error("VALIDATION_ERROR", e.getMessage(), 400)
        );
    }
    
    @ExceptionHandler(InvalidImageException.class)
    public ResponseEntity<ApiResponse<?>> handleInvalidImageException(
        InvalidImageException e
    ) {
        log.warn("Invalid image: {}", e.getMessage());
        return ResponseEntity.badRequest().body(
            ApiResponse.error("INVALID_IMAGE", e.getMessage(), 400)
        );
    }
    
    @ExceptionHandler(ProcessingException.class)
    public ResponseEntity<ApiResponse<?>> handleProcessingException(
        ProcessingException e
    ) {
        log.error("Processing error: {}", e.getMessage(), e);
        return ResponseEntity.status(500).body(
            ApiResponse.error("PROCESSING_ERROR", e.getMessage(), 500)
        );
    }
    
    @ExceptionHandler(ImageNotFoundException.class)
    public ResponseEntity<ApiResponse<?>> handleImageNotFound(
        ImageNotFoundException e
    ) {
        log.warn("Image not found: {}", e.getMessage());
        return ResponseEntity.status(404).body(
            ApiResponse.error("NOT_FOUND", e.getMessage(), 404)
        );
    }
    
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<?>> handleGenericException(
        Exception e
    ) {
        log.error("Unexpected error", e);
        return ResponseEntity.status(500).body(
            ApiResponse.error(
                "INTERNAL_ERROR", 
                "An unexpected error occurred", 
                500
            )
        );
    }
}
```

---

## 5. Validation

### Input Validation (Controller Level)

```java
@PostMapping("/invert")
public ResponseEntity<ApiResponse<ImageInvertResponse>> invertImage(
    @Valid @RequestBody ImageInvertRequest request
) {
    // Spring validates @Valid annotations automatically
    // Validation errors trigger 400 Bad Request
    
    ImageInvertResponse response = imageService.invertImage(request);
    return ResponseEntity.ok(ApiResponse.success(response));
}
```

### Business Logic Validation (Domain Level)

```java
public class ImageInversionService {
    
    public InversionResult invert(ImageData imageData) {
        ValidationReport report = validate(imageData);
        
        if (!report.isValid()) {
            throw new ValidationException(
                report.getErrors().stream()
                    .map(ErrorDetail::getMessage)
                    .collect(Collectors.joining(", "))
            );
        }
        
        // Process...
    }
    
    private ValidationReport validate(ImageData imageData) {
        List<ErrorDetail> errors = new ArrayList<>();
        
        if (imageData.getWidth() < 1 || imageData.getWidth() > 4096) {
            errors.add(new ErrorDetail(
                "INVALID_WIDTH",
                "Width must be between 1 and 4096 pixels",
                400
            ));
        }
        
        if (imageData.getHeight() < 1 || imageData.getHeight() > 4096) {
            errors.add(new ErrorDetail(
                "INVALID_HEIGHT",
                "Height must be between 1 and 4096 pixels",
                400
            ));
        }
        
        return new ValidationReport(errors.isEmpty(), errors);
    }
}
```

---

## 6. Data Flow Diagram

```
┌─────────────────────────────────────┐
│         HTTP Request (JSON)         │
│  POST /api/v1/images/invert         │
│  ImageInvertRequest DTO             │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│    L₂: Controller Adapter           │
│  ImageController.invertImage()      │
│  - Deserialize DTO                  │
│  - Route to service                 │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│    ACL: DTO → Domain Model          │
│  ImageInvertRequest → ImageData     │
│  ImageInvertRequest → Image Entity  │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│    L₁: Application Service          │
│  ImageService.invertImage()         │
│  - Validate request                 │
│  - Coordinate domain logic          │
│  - Manage transaction               │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│    L₀: Domain Service               │
│  ImageInversionService.invert()     │
│  - Business logic                   │
│  - Publish events                   │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│    L₃: Framework (Image Processor)  │
│  AwtImageProcessor.invertPixels()   │
│  - Pixel manipulation               │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│    Result: InversionResult          │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│    L₁: Repository (Persistence)     │
│  ImageRepository.save()             │
│  - Save aggregate to database       │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│    Event Publishing                 │
│  ImageInvertedEvent emitted         │
│  Handlers process async             │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│    ACL: Entity → Response DTO       │
│  Image → ImageInvertResponse        │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│    L₂: Controller Response           │
│  Return ApiResponse<DTO>            │
│  Serialize JSON                     │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│      HTTP Response (200 OK)         │
│  Content-Type: application/json     │
│  ImageInvertResponse JSON           │
└─────────────────────────────────────┘
```

---

## 7. Testing REST API

### Unit Testing Controller

```java
@WebMvcTest(ImageController.class)
public class ImageControllerTest {
    
    @MockBean
    private ImageService imageService;
    
    @Autowired
    private MockMvc mockMvc;
    
    @Test
    public void shouldInvertImageSuccessfully() throws Exception {
        // Arrange
        ImageInvertRequest request = ImageInvertRequest.builder()
            .imageBase64("iVBORw0KGgoAAAA...")
            .format("PNG")
            .build();
        
        ImageInvertResponse response = ImageInvertResponse.builder()
            .id(UUID.randomUUID())
            .state("COMPLETED")
            .invertedImageBase64("iVBORw0KGgoAAAA...")
            .processingTimeMills(250L)
            .build();
        
        when(imageService.invertImage(any()))
            .thenReturn(response);
        
        // Act & Assert
        mockMvc.perform(
            post("/api/v1/images/invert")
                .contentType(MediaType.APPLICATION_JSON)
                .content(asJsonString(request))
        )
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.state").value("COMPLETED"));
    }
}
```

### Integration Testing

```java
@SpringBootTest
@AutoConfigureMockMvc
public class ImageApiIntegrationTest {
    
    @Autowired
    private MockMvc mockMvc;
    
    @Autowired
    private ImageRepository repository;
    
    @Test
    @Transactional
    public void shouldProcessImageAndPersist() throws Exception {
        // Arrange
        ImageInvertRequest request = ImageInvertRequest.builder()
            .imageBase64(createTestImageBase64())
            .format("PNG")
            .build();
        
        // Act
        MvcResult result = mockMvc.perform(
            post("/api/v1/images/invert")
                .contentType(MediaType.APPLICATION_JSON)
                .content(asJsonString(request))
        )
        .andExpect(status().isOk())
        .andReturn();
        
        // Extract ID from response
        String content = result.getResponse().getContentAsString();
        UUID imageId = extractIdFromResponse(content);
        
        // Assert: Verify persistence
        Image savedImage = repository.findById(imageId);
        assertNotNull(savedImage);
        assertEquals(State.COMPLETED, savedImage.getState());
    }
}
```

---

## 8. Documentation & Versioning

### API Version Strategy
- **Current Version:** `/api/v1`
- **Backward Compatibility:** Keep v1 endpoints working
- **New Features:** Create v2 if breaking changes needed

### OpenAPI/Swagger Documentation

```java
@Configuration
public class SwaggerConfiguration {
    
    @Bean
    public OpenAPI imageInverterOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("Image Inverter API")
                .description("RESTful API for image inversion processing")
                .version("1.0.0")
                .contact(new Contact()
                    .name("Development Team")
                    .url("https://github.com/your-repo"))
            )
            .servers(List.of(
                new Server()
                    .url("http://localhost:8080")
                    .description("Development"),
                new Server()
                    .url("https://api.example.com")
                    .description("Production")
            ));
    }
}
```

---

## Best Practices Checklist

✅ **Endpoint Naming** - Use nouns (`/images`), not verbs  
✅ **HTTP Methods** - POST (create), GET (read), PUT/PATCH (update), DELETE  
✅ **Status Codes** - 200 (OK), 201 (Created), 400 (Bad Request), 404 (Not Found), 500 (Server Error)  
✅ **Versioning** - Include in URL path (`/api/v1`)  
✅ **Error Responses** - Consistent error format  
✅ **Input Validation** - Validate at controller boundary  
✅ **DTOs** - Separate from domain models (ACL)  
✅ **Response Wrapping** - Consistent API response format  
✅ **Documentation** - OpenAPI/Swagger  
✅ **Testing** - Unit & integration tests  

---

**Last Updated:** December 18, 2025  
**Version:** 1.0  
**Status:** Active Reference
