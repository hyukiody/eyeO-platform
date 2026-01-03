# Image Inverter - Architecture Reference Guide

## Quick Reference Index

### 1. Domain-Driven Design Quick Map
| Component | Location | Purpose |
|-----------|----------|---------|
| Entities | `backend/domain/entities/` | Objects with identity & lifecycle |
| Value Objects | `backend/domain/value_objects/` | Immutable, defined by attributes |
| Aggregates | `backend/domain/` | Consistency boundaries |
| Repositories | `backend/repositories/` | Data access abstraction |
| Domain Services | `backend/services/` | Domain logic operations |

### 2. Bounded Contexts

#### Image Processing Context (Primary)
```
Package: backend.*
Entities: Image, ProcessingJob, InversionResult
Entry Point: ImageController (REST API)
Repository: ImageRepository
```

**Key Operations:**
- `POST /api/images/invert` → Invert image (application use case)
- `GET /api/images/{id}` → Retrieve image
- `GET /api/processing/{jobId}/status` → Track processing progress

#### Authentication Context
```
Package: backend/authentication/*
Entities: User, Session, Role
Services: AuthenticationService, TokenService
Repository: UserRepository
```

#### GUI Context (Legacy)
```
Package: backend.entities.gui
Classes: MainFrame, SwingImageClient
Type: Presentation Adapter (L₂)
```

---

### 3. Clean Architecture Layer Mapping

```
┌─────────────────────────────────────────┐
│  L₃: Framework & Drivers                │
│  (Spring Boot, AWT, Database, HTTP)     │
├─────────────────────────────────────────┤
│  L₂: Interface Adapters                 │
│  (Controllers, GUI, Gateways)           │
├─────────────────────────────────────────┤
│  L₁: Application Services               │
│  (Use Cases, DTOs, Coordinators)        │
├─────────────────────────────────────────┤
│  L₀: Domain Layer                       │
│  (Entities, ValueObjects, Services)     │
└─────────────────────────────────────────┘
        Dependency Flow: ↓ (inner)
```

**Image Inverter Layer Assignment:**

**Layer 0 (Domain) - `backend/domain/`**
```
├── entities/
│   ├── Image (Entity with identity)
│   ├── ProcessingJob (Entity with state)
│   └── InversionResult (ValueObject)
├── value_objects/
│   ├── ImageData (immutable pixel data)
│   └── ProcessingMetadata
├── services/
│   ├── ImageInversionService (domain logic)
│   └── ValidationService
└── repositories/
    ├── ImageRepository (port/interface)
    └── ProcessingJobRepository (port/interface)
```

**Layer 1 (Application) - `backend/services/` & `backend/dto/`**
```
├── ImageService (orchestrates use cases)
├── ProcessingService (manages workflow)
├── dto/
│   ├── ImageInvertRequest (input)
│   ├── ImageInvertResponse (output)
│   └── ProcessingStatusDTO (query result)
└── converters/
    └── DTOConverter (ACL translation)
```

**Layer 2 (Adapters) - `backend/controllers/` & UI**
```
├── ImageController (REST adapter)
│   ├── POST /api/images/invert
│   ├── GET /api/images/{id}
│   └── GET /api/processing/{jobId}/status
├── AuthController (Auth adapter)
├── gateways/
│   └── ImageRepositoryAdapter (JPA implementation)
└── gui/
    ├── MainFrame (Swing adapter)
    └── SwingImageClient (Legacy GUI)
```

**Layer 3 (Framework) - External & Configuration**
```
├── processor/
│   ├── AwtImageProcessor (AWT Framework)
│   └── ImageProcessor (Image API)
├── worker/
│   └── ImageProcessingWorker (Threading)
├── JPA Entities (Hibernate mapping)
└── Spring Boot Configuration
```

---

### 4. Anti-Corruption Layer (ACL) Pattern

#### Purpose
Translate between REST requests and domain models

#### Image Inverter ACL

**Inbound ACL (REST → Domain):**
```
REST Request JSON:
{
  "imageBase64": "iVBORw0KGgoAAAAN...",
  "format": "PNG"
}
  ↓ (DTOConverter.toImageEntity)
Domain Entity:
Image {
  id: UUID.randomUUID(),
  data: ImageData { bytes, width, height, format },
  state: State.PENDING,
  createdAt: Instant.now()
}
```

**Outbound ACL (Domain → REST):**
```
Domain Entity:
Image {
  id: UUID,
  data: ImageData { ... },
  result: InversionResult { ... },
  state: COMPLETED
}
  ↓ (DTOConverter.toImageResponse)
REST Response JSON:
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "status": "COMPLETED",
  "originalImageBase64": "iVBORw0K...",
  "invertedImageBase64": "iVBORw0K...",
  "processingTime_ms": 245
}
```

---

### 5. Repository Pattern

#### Image Repository Example

**Port (Interface) - L₀:**
```java
// src/main/java/backend/domain/repositories/ImageRepository.java
public interface ImageRepository {
    void save(Image image);
    Image findById(UUID id);
    List<Image> findByStatus(State status);
    void delete(UUID id);
}
```

**Adapter (Implementation) - L₃:**
```java
// src/main/java/backend/repositories/ImageRepositoryAdapter.java
@Repository
public class ImageRepositoryAdapter implements ImageRepository {
    private final ImageJpaRepository jpaRepository;
    
    @Override
    public void save(Image image) {
        ImageEntity entity = mapper.toEntity(image);
        jpaRepository.save(entity);
    }
}
```

**Usage in Application Service - L₁:**
```java
// src/main/java/backend/services/ImageService.java
@Service
public class ImageService {
    private final ImageRepository repository;
    
    public ImageInvertResponse invertImage(ImageInvertRequest request) {
        Image image = createImage(request);
        repository.save(image);  // Persistence
        return toResponse(image);
    }
}
```

---

### 6. Event-Driven Flow

#### Domain Events

**1. ImageInvertedEvent (Success)**
```
Generated by: ImageInversionService
Published to: ApplicationEventPublisher
Payload: {
    aggregateId: UUID,
    invertedImageId: UUID,
    duration_ms: long,
    timestamp: Instant
}
Handlers:
  - Update Image status to COMPLETED
  - Send notification to user
  - Update metrics
```

**2. ProcessingFailedEvent (Error)**
```
Generated by: ImageInversionService (on exception)
Payload: {
    aggregateId: UUID,
    errorMessage: String,
    errorCode: String,
    timestamp: Instant
}
Handlers:
  - Update Image status to FAILED
  - Log error for analysis
  - Trigger retry logic
```

**3. ProcessingScheduledEvent**
```
Generated by: ProcessingService
Payload: {
    aggregateId: UUID,
    jobId: UUID,
    priority: int,
    scheduledTime: Instant
}
Handlers:
  - Enqueue job for worker
  - Send acknowledgment to client
```

---

### 7. REST API as Open Host Service (OHS)

#### Endpoint Classification

| Method | Endpoint | Layer | Use Case |
|--------|----------|-------|----------|
| POST | `/api/images/invert` | L₂→L₁→L₀ | Invert Image |
| GET | `/api/images/{id}` | L₂→L₁→L₀ | Get Image Details |
| GET | `/api/processing/{jobId}/status` | L₂→L₁→L₀ | Track Progress |
| GET | `/api/statistics` | L₂→L₁→Query | Get Statistics |
| DELETE | `/api/images/{id}` | L₂→L₁→L₀ | Delete Image |

#### Data Flow Example: POST /api/images/invert

```
1. HTTP Request (JSON)
   ↓ [L₂ - Controller]
2. ImageInvertRequest DTO deserialized
   ↓ [ACL Translation]
3. ImageInvertRequest → Image Entity (domain object)
   ↓ [L₁ - Application Service]
4. ImageService.invertImage(request)
   ↓ [L₀ - Domain Service]
5. ImageInversionService.process(imageData)
   ↓ [L₃ - Framework: AwtImageProcessor]
6. Pixel inversion algorithm executed
   ↓ [Result]
7. InversionResult created
   ↓ [L₁ - Repository]
8. Image entity saved to database
   ↓ [Event Published]
9. ImageInvertedEvent emitted
   ↓ [ACL Translation]
10. InversionResult → ImageInvertResponse DTO
    ↓ [L₂ - Controller]
11. HTTP Response (JSON) returned
```

---

### 8. Type Safety & Generics

#### Generic Repository Pattern
```java
public interface Repository<T extends Entity> {
    void save(T entity);
    T findById(UUID id);
    List<T> findAll();
}

// Applied:
public interface ImageRepository extends Repository<Image> { }
public interface ProcessingJobRepository extends Repository<ProcessingJob> { }
```

#### Generic Response Wrapper
```java
public class ApiResponse<T> {
    private boolean success;
    private T data;
    private List<ErrorDetail> errors;
    
    // Usage:
    ApiResponse<ImageInvertResponse> response = ...;
    ApiResponse<List<ImageDTO>> imageList = ...;
}
```

---

### 9. State Machine (Image Processing)

```
┌─────────┐
│ PENDING │ (Initial state)
└────┬────┘
     │ (submit)
     ↓
┌──────────────┐
│ VALIDATION   │ (Validate input)
└────┬─────┬──┘
     │     │
  valid  invalid
     │     │
     ↓     ↓
  ┌─────────┐
  │ QUEUED  │ FAILED (ValidationError)
  └────┬────┘
       │ (worker available)
       ↓
  ┌────────────┐
  │ PROCESSING │ (Invert pixels)
  └────┬────┬──┘
       │    │
    success error
       │    │
       ↓    ↓
  ┌─────────────┐
  │ COMPLETED   │ FAILED (ProcessingError)
  └─────────────┘
```

---

### 10. Dependency Injection Map

**Spring Bean Wiring:**

```
@Configuration
public class BeansConfiguration {
    
    // Layer 0: Domain Services
    @Bean
    public ImageInversionService imageInversionService() {
        return new ImageInversionService(new AwtImageProcessor());
    }
    
    // Layer 1: Application Services
    @Bean
    public ImageService imageService(
        ImageRepository repository,
        ImageInversionService domainService
    ) {
        return new ImageService(repository, domainService);
    }
    
    // Layer 2: Controllers
    @Bean
    public ImageController imageController(ImageService service) {
        return new ImageController(service);
    }
    
    // Layer 3: Adapters & Repositories
    @Bean
    public ImageRepository imageRepository(
        ImageJpaRepository jpaRepository
    ) {
        return new ImageRepositoryAdapter(jpaRepository);
    }
}
```

---

### 11. Quick Checklist: Adding New Feature

✅ **Step 1: Define Domain (L₀)**
- [ ] Create Entity or ValueObject
- [ ] Define state machine (if stateful)
- [ ] Create Repository interface (port)

✅ **Step 2: Create Application Service (L₁)**
- [ ] Write use case logic
- [ ] Create Request DTO
- [ ] Create Response DTO
- [ ] Implement ACL conversion

✅ **Step 3: Build Controller (L₂)**
- [ ] Create REST endpoint
- [ ] Map request/response
- [ ] Add validation

✅ **Step 4: Implement Repository Adapter (L₃)**
- [ ] Create JPA entity
- [ ] Implement repository interface
- [ ] Add database mappings

✅ **Step 5: Add Events & Handlers**
- [ ] Define DomainEvent
- [ ] Create @EventListener
- [ ] Handle side effects

---

### 12. Common Patterns

#### Use Case Implementation Pattern
```java
@Service
public class MyService {
    private final MyRepository repository;
    private final MyDomainService domainService;
    private final ApplicationEventPublisher eventPublisher;
    
    public MyResponse execute(MyRequest request) {
        // 1. Validate input
        validateRequest(request);
        
        // 2. Load aggregate
        MyEntity entity = repository.findById(request.getId());
        
        // 3. Call domain service
        Result result = domainService.process(entity);
        
        // 4. Save changes
        repository.save(entity);
        
        // 5. Publish event
        eventPublisher.publishEvent(new MyEvent(...));
        
        // 6. Return response (ACL)
        return toResponse(entity);
    }
}
```

#### Error Handling Pattern
```java
@ControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(ValidationException.class)
    public ResponseEntity<ErrorResponse> handle(ValidationException e) {
        return ResponseEntity.badRequest().body(
            new ErrorResponse("VALIDATION_ERROR", e.getMessage())
        );
    }
    
    @ExceptionHandler(ProcessingException.class)
    public ResponseEntity<ErrorResponse> handle(ProcessingException e) {
        return ResponseEntity.status(500).body(
            new ErrorResponse("PROCESSING_ERROR", e.getMessage())
        );
    }
}
```

---

## Related Documentation

- [LOGIC_NOTATION.md](./LOGIC_NOTATION.md) - Formal definitions & notation
- [API_DESIGN.md](../../API_DESIGN.md) - REST API specification
- [DDD_PATTERNS.md](../patterns/DDD_PATTERNS.md) - Detailed DDD patterns
- [EVENT_DRIVEN.md](../patterns/EVENT_DRIVEN.md) - Event patterns

---

**Last Updated:** December 18, 2025  
**Version:** 1.0  
**Status:** Active Reference
