# Image Inverter - Complete Architecture Setup Guide

## 📋 Project Overview

The **Image Inverter** project is architected using:
- **Domain-Driven Design (DDD)** for business logic organization
- **Clean/Hexagonal Architecture** for layer separation and testability
- **Event-Driven Architecture** for asynchronous communication
- **REST API** as Open Host Service for external integration
- **Spring Boot** for framework and dependency management

---

## 🗂 Documentation Structure

### Quick Reference Documents
| Document | Purpose | Location |
|----------|---------|----------|
| **LOGIC_NOTATION.md** | Formal definitions & mathematical notation | `docs/architecture/` |
| **ARCHITECTURE_REFERENCE.md** | Quick reference mapping to codebase | `docs/architecture/` |
| **DDD_PATTERNS.md** | Implementation patterns with code examples | `docs/patterns/` |
| **EVENT_DRIVEN.md** | Event patterns and handlers | `docs/patterns/` |
| **API_DESIGN.md** | REST API specification and DTOs | `docs/` |

---

## 🏗 Architecture Layers

### Layer 0: Domain Layer (`backend/domain/`)
**Responsibility:** Pure business logic, independent of framework

**Components:**
```
domain/
├── entities/
│   ├── Image.java (Entity with identity & lifecycle)
│   └── ProcessingJob.java (Stateful entity)
├── value_objects/
│   ├── ImageData.java (Immutable pixel data)
│   ├── InversionResult.java (Processing result)
│   └── ProcessingMetadata.java
├── services/
│   └── ImageInversionService.java (Domain business logic)
├── repositories/
│   ├── ImageRepository.java (Port/Interface)
│   └── ProcessingJobRepository.java (Port/Interface)
├── aggregates/
│   └── ImageProcessingAggregate.java (Consistency boundary)
├── events/
│   ├── DomainEvent.java (Base event)
│   ├── ImageInvertedEvent.java
│   ├── ProcessingFailedEvent.java
│   └── ProcessingScheduledEvent.java
├── specifications/
│   └── ImageSpecification.java (Business rules)
└── factories/
    └── ImageFactory.java (Complex object creation)
```

**Key Classes:**
- `Image` - Entity with state machine (PENDING → PROCESSING → COMPLETED)
- `ImageData` - ValueObject representing pixel data
- `InversionResult` - ValueObject with processing metrics
- `ImageInversionService` - Domain service for inversion logic

---

### Layer 1: Application Layer (`backend/services/` & `backend/dto/`)
**Responsibility:** Use case coordination, DTO conversion (ACL)

**Components:**
```
services/
├── ImageService.java (Main use case orchestrator)
├── ProcessingService.java (Job management)
├── handlers/
│   ├── ImageInvertedEventHandler.java (Event listener)
│   ├── ProcessingFailedEventHandler.java
│   └── ProcessingScheduledEventHandler.java
└── converters/
    └── DTOConverter.java (ACL: DTO ↔ Domain)

dto/
├── ImageInvertRequest.java (Input DTO)
├── ImageInvertResponse.java (Output DTO)
├── ProcessingStatusDTO.java (Query result)
└── ApiResponse.java (Generic response wrapper)
```

**Key Responsibilities:**
- Coordinate domain services
- Manage transactions
- Convert DTOs to/from domain models (ACL)
- Publish events after domain operations

---

### Layer 2: Interface Adapter Layer (`backend/controllers/` & `gui/`)
**Responsibility:** Express external inputs/outputs in API-friendly format

**Components:**
```
controllers/
├── ImageController.java (REST endpoints)
│   ├── POST /api/v1/images/invert
│   ├── GET /api/v1/images/{id}
│   ├── GET /api/v1/processing/{jobId}/status
│   ├── GET /api/v1/statistics
│   └── DELETE /api/v1/images/{id}
├── AuthController.java (Authentication endpoints)
└── gateways/
    └── ImageRepositoryAdapter.java (Repository implementation)

gui/
├── MainFrame.java (Swing GUI adapter)
└── SwingImageClient.java (Legacy client)
```

**Key Responsibilities:**
- Deserialize HTTP requests to DTOs
- Validate input using Spring validation
- Call application services
- Serialize responses to JSON
- Handle HTTP error codes

---

### Layer 3: Framework & Drivers (`backend/processor/`, `worker/`, Config)
**Responsibility:** Specific technology implementations

**Components:**
```
processor/
├── AwtImageProcessor.java (AWT-based pixel inversion)
└── ImageProcessor.java (Image API wrapper)

worker/
└── ImageProcessingWorker.java (Swing Worker for threading)

config/
├── BeansConfiguration.java (Dependency injection)
├── EventListenerConfiguration.java (Async event setup)
├── PersistenceConfiguration.java (JPA setup)
└── SwaggerConfiguration.java (API documentation)

jpa/
└── ImageEntity.java (Hibernate mapping)
```

**Key Responsibilities:**
- Framework-specific code
- Database mappings
- External API integrations
- Threading and concurrency

---

## 🔄 Data Flow Example: Image Inversion

```
1. HTTP Request arrives
   ↓
2. ImageController.invertImage() deserializes ImageInvertRequest
   ↓
3. ACL converts DTO → ImageData (ValueObject)
   ↓
4. ImageService.invertImage() orchestrates:
   - Creates Image aggregate
   - Saves to repository
   - Publishes ProcessingScheduledEvent
   ↓
5. ImageInversionService.invert() (Domain Service):
   - Validates image data
   - Calls AwtImageProcessor
   - Returns InversionResult
   ↓
6. Image entity updated with result
   ↓
7. ImageInvertedEvent published
   ↓
8. Event handlers process asynchronously:
   - Update statistics
   - Send notifications
   - Trigger post-processing
   ↓
9. ACL converts Image → ImageInvertResponse
   ↓
10. Controller returns ApiResponse<ImageInvertResponse>
    ↓
11. HTTP 200 OK with JSON response
```

---

## 🔗 Bounded Contexts

### Image Processing Context (Primary)
**Purpose:** Core image inversion business logic

**Aggregate:** `ImageProcessingAggregate`
- Root: `Image`
- Children: `ImageData`, `ProcessingMetadata`, `InversionResult`

**Invariants:**
- Image must have valid pixel data
- Cannot be processed twice
- State follows state machine

**Events:**
- `ImageInvertedEvent` (success)
- `ProcessingFailedEvent` (error)
- `ProcessingScheduledEvent` (queued)

---

### Authentication Context
**Purpose:** User identity and authorization

**Entities:**
- `User`
- `Session`
- `Role`

**Repository:** `UserRepository`

**Integration:** ACL with Image Processing Context

---

### GUI Context (Legacy)
**Purpose:** Swing-based presentation

**Components:**
- `MainFrame` (Main window)
- `SwingImageClient` (Client adapter)

**Status:** Maintained for backward compatibility

---

## 📊 Dependency Injection Map

### Bean Configuration

```java
@Configuration
public class BeansConfiguration {
    
    // L₃ Framework Services
    @Bean
    public ImageProcessor imageProcessor() {
        return new AwtImageProcessor();
    }
    
    // L₀ Domain Services
    @Bean
    public ImageInversionService imageInversionService(
        ImageProcessor processor
    ) {
        return new ImageInversionServiceImpl(processor);
    }
    
    // L₁ Application Services
    @Bean
    public ImageService imageService(
        ImageRepository repository,
        ImageInversionService domainService,
        ApplicationEventPublisher eventPublisher
    ) {
        return new ImageService(repository, domainService, eventPublisher);
    }
    
    // L₂ Controllers
    @Bean
    public ImageController imageController(
        ImageService service,
        DTOConverter converter
    ) {
        return new ImageController(service, converter);
    }
    
    // L₃ Repository Adapters
    @Bean
    public ImageRepository imageRepository(
        ImageJpaRepository jpaRepository,
        ImageMapper mapper
    ) {
        return new ImageRepositoryAdapter(jpaRepository, mapper);
    }
}
```

---

## 🚀 Quick Start: Adding a New Feature

### Example: Add Image Format Conversion

#### Step 1: Define Domain Model (L₀)

```java
// backend/domain/entities/ConversionJob.java
public class ConversionJob implements Entity<UUID> {
    private final UUID id;
    private final Image sourceImage;
    private ImageFormat targetFormat;
    private State state;
    
    // ... lifecycle methods
}

// backend/domain/value_objects/ConversionResult.java
public final class ConversionResult {
    private final byte[] convertedPixels;
    private final String convertedFormat;
    // ... immutable
}
```

#### Step 2: Add Domain Service (L₀)

```java
// backend/domain/services/ImageConversionService.java
public interface ImageConversionService {
    ConversionResult convert(ImageData imageData, ImageFormat targetFormat);
}

@Service
public class ImageConversionServiceImpl implements ImageConversionService {
    // Implementation with business logic
}
```

#### Step 3: Create Application Service (L₁)

```java
// backend/services/ImageConversionService.java
@Service
public class ConversionApplicationService {
    
    private final ImageRepository repository;
    private final ImageConversionService conversionService;
    private final ApplicationEventPublisher eventPublisher;
    
    public ConversionResponse convertImage(ConversionRequest request) {
        // Orchestrate: validate → process → persist → publish
    }
}
```

#### Step 4: Create REST Endpoint (L₂)

```java
// backend/controllers/ConversionController.java
@RestController
@RequestMapping("/api/v1/convert")
public class ConversionController {
    
    @PostMapping
    public ResponseEntity<ApiResponse<ConversionResponse>> convert(
        @Valid @RequestBody ConversionRequest request
    ) {
        ConversionResponse response = 
            conversionService.convertImage(request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}
```

#### Step 5: Create DTOs (L₁ - ACL)

```java
// backend/dto/ConversionRequest.java
@Data
public class ConversionRequest {
    private String imageBase64;
    private String targetFormat;
}

// backend/dto/ConversionResponse.java
@Data
public class ConversionResponse {
    private UUID id;
    private String convertedImageBase64;
}
```

#### Step 6: Add Repository (L₃)

```java
// backend/repositories/ConversionJobRepository.java
@Repository
public interface ConversionJobRepository 
    extends Repository<ConversionJob> {
    List<ConversionJob> findByStatus(State status);
}
```

#### Step 7: Implement (L₃)

```java
// backend/processors/ImageConversionProcessor.java
@Component
public class ImageConversionProcessor {
    public BufferedImage convert(BufferedImage source, 
                                String targetFormat) {
        // Framework-specific conversion logic
    }
}
```

---

## 🧪 Testing Strategy

### Unit Testing (Domain Layer)

```java
@ExtendWith(MockitoExtension.class)
public class ImageInversionServiceTest {
    
    private ImageInversionService service;
    private ImageProcessor processor;
    
    @Test
    public void shouldInvertPixelsCorrectly() {
        // Pure domain logic test
        // No dependencies on framework
    }
}
```

### Integration Testing (Application Layer)

```java
@SpringBootTest
public class ImageServiceIntegrationTest {
    
    @Autowired
    private ImageService service;
    
    @Autowired
    private ImageRepository repository;
    
    @Test
    public void shouldPersistAfterProcessing() {
        // Test coordination across layers
    }
}
```

### API Testing (Controller Layer)

```java
@WebMvcTest(ImageController.class)
public class ImageControllerTest {
    
    @Autowired
    private MockMvc mockMvc;
    
    @Test
    public void shouldReturnInvertedImageResponse() 
        throws Exception {
        // Test REST interface
    }
}
```

---

## 📝 Key Patterns Applied

| Pattern | Where | Purpose |
|---------|-------|---------|
| **Entity** | Image, ProcessingJob | Objects with identity |
| **ValueObject** | ImageData, InversionResult | Immutable data |
| **Repository** | ImageRepository | Data access abstraction |
| **Service** | ImageInversionService | Domain logic |
| **Factory** | ImageFactory | Complex object creation |
| **Aggregate** | ImageProcessingAggregate | Consistency boundaries |
| **DTOs** | ImageInvertRequest/Response | API contracts (ACL) |
| **Events** | ImageInvertedEvent | Loose coupling |
| **Handlers** | ImageInvertedEventHandler | Async processing |
| **Specification** | ImageSpecification | Business rules |

---

## 🔐 Validation & Error Handling

### Input Validation (Controller)

```java
@PostMapping("/invert")
public ResponseEntity<?> invertImage(
    @Valid @RequestBody ImageInvertRequest request
) {
    // Spring validates @NotNull, @Pattern, etc.
}
```

### Business Logic Validation (Domain)

```java
public InversionResult invert(ImageData imageData) {
    ValidationReport report = validate(imageData);
    if (!report.isValid()) {
        throw new ValidationException(report.getErrors());
    }
}
```

### Centralized Error Handling

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(ValidationException.class)
    public ResponseEntity<?> handleValidation(ValidationException e) {
        return ResponseEntity.badRequest()
            .body(ApiResponse.error("VALIDATION_ERROR", e.getMessage(), 400));
    }
}
```

---

## 📈 Monitoring & Observability

### Key Metrics

```
- totalProcessed: Long
- successCount: Long
- failureCount: Long
- avgProcessingTime_ms: Double
- p99ProcessingTime_ms: Double
```

### Event-Driven Observability

All domain events are logged and tracked:
- `ImageInvertedEvent` → Success
- `ProcessingFailedEvent` → Failure
- `ProcessingScheduledEvent` → Queued

### Health Endpoints

```
GET /actuator/health
GET /actuator/metrics
GET /api/v1/statistics
```

---

## 🔄 State Machine

```
Initial: PENDING
    ↓ (submit)
VALIDATION
    ├─→ (valid) → QUEUED
    └─→ (invalid) → FAILED

QUEUED
    ↓ (worker takes)
PROCESSING
    ├─→ (success) → COMPLETED
    └─→ (error) → FAILED

COMPLETED / FAILED
    ↓ (archive)
ARCHIVED
```

---

## 📚 Related Documentation

1. **LOGIC_NOTATION.md** - Mathematical formalism
2. **ARCHITECTURE_REFERENCE.md** - Layer-to-code mapping
3. **DDD_PATTERNS.md** - Pattern implementations
4. **EVENT_DRIVEN.md** - Event architecture
5. **API_DESIGN.md** - REST API specification

---

## ✅ Implementation Checklist

- [x] Domain layer entities and value objects
- [x] Repository interfaces (ports)
- [x] Domain services with business logic
- [x] Application services coordinating use cases
- [x] REST controllers with endpoint mapping
- [x] DTOs for ACL (request/response)
- [x] Error handling and validation
- [x] Event publishing and handling
- [x] Database adapters (repositories)
- [x] Unit and integration tests
- [x] API documentation (OpenAPI/Swagger)
- [x] Dependency injection configuration

---

## 🎯 Next Steps

1. **Run existing tests** to verify architecture
2. **Extend with new features** following patterns
3. **Monitor metrics** from processing events
4. **Add authentication** using bounded context pattern
5. **Scale with message broker** (Kafka, RabbitMQ) if needed
6. **Implement event sourcing** for audit trail (optional)

---

**Last Updated:** December 18, 2025  
**Version:** 1.0  
**Architecture Status:** ✅ Complete & Documented
