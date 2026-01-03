# Image Inverter - Logic Notation & Formal Definitions

## Overview
This document defines the formal logic notation used in the Image Inverter project, based on Domain-Driven Design (DDD), Clean/Hexagonal Architecture, and Event-Driven patterns.

---

## 1. Domain-Driven Design (DDD) Building Blocks

### Formal Definition
Let:
- `Entity(E)` = Object with identity and lifecycle (changes over time)
- `ValueObject(VO)` = Immutable object defined by attributes (equality by value)
- `Aggregate(A)` = Cluster of associated objects (root entity + consistency boundary)
- `Repository(R)` = Abstraction for persistence/retrieval of aggregates
- `Service(S)` = Domain operation not belonging to Entity or ValueObject
- `DomainEvent(DE)` = Significant fact that occurred in the domain

**Formal Notation:**
```
Domain = {E, VO, A, R, S, DE}
```

### Image Inverter Applied to DDD

#### Entities
```
ImageEntity(id, createdAt, modifiedAt) {
    - identity: UUID
    - state: PENDING | PROCESSING | COMPLETED | FAILED
    - lifecycle: created → processed → archived
}
```

#### Value Objects
```
ImageData(width, height, format, colorSpace) {
    - immutable
    - equality by attribute values
}

InversionResult(inverted_pixels, execution_time_ms) {
    - immutable
    - represents outcome
}
```

#### Aggregates
```
ImageProcessingAggregate {
    root: ImageEntity
    children: [ImageData, ProcessingMetadata, InversionResult]
    invariants:
        - image cannot be processed twice
        - result depends on image data consistency
}
```

#### Repositories
```
Repository(R) implements:
    save(aggregate: A) → void
    findById(id: UUID) → A
    findByStatus(status: String) → List<A>
    delete(id: UUID) → void
```

#### Domain Services
```
ImageInversionService: {
    invertImage(imageData: ImageData) → InversionResult,
    validateImage(imageData: ImageData) → Boolean,
    scheduleProcessing(imageEntity: Entity) → void
}
```

---

## 2. Bounded Context Mapping

### Context Definition
Let:
- `BC₁, BC₂, ...` = Bounded Contexts (subdomains with explicit boundaries)
- `SK` = Shared Kernel (shared model between contexts)
- `CS` = Customer-Supplier (upstream/downstream relationship)
- `ACL` = Anti-Corruption Layer (translates models)
- `OHS` = Open Host Service (public API)

### Image Inverter Bounded Contexts

**Context 1: Image Processing Domain**
```
ImageProcessingBC = {
    Entities: {Image, ProcessingJob, InversionResult},
    ValueObjects: {ImageData, ProcessingMetadata},
    Services: {ImageInversionService, ValidationService},
    Repository: ImageRepository
}
```

**Context 2: Authentication & Authorization Domain**
```
AuthenticationBC = {
    Entities: {User, Session, Role},
    ValueObjects: {Credentials, Permission},
    Services: {AuthService, TokenService},
    Repository: UserRepository
}
```

**Context 3: GUI/Presentation Domain**
```
PresentationBC = {
    Entities: {UIState, UserPreferences},
    ValueObjects: {DisplayFormat, Theme},
    Services: {RenderService, EventBroadcaster},
    Repository: PreferenceRepository
}
```

### Context Relationships

**Anti-Corruption Layer (ImageProcessing ↔ Authentication):**
```
ACL: {
    external_user_id → internal_user_reference,
    external_permission → internal_role_mapping,
    translation: authenticateUser() → SessionToken
}
```

**Open Host Service (REST API):**
```
OHS: ImageProcessingBC → REST API → {
    WebClient,
    MobileClient,
    ThirdPartyService
}
```

---

## 3. Hexagonal/Clean Architecture Layers

### Layer Definition
Let layers be:
- `L₀` = Domain Layer (Entities, Value Objects, Aggregates, Repositories)
- `L₁` = Application Layer (Use Cases, Application Services, DTOs)
- `L₂` = Interface Adapter Layer (Controllers, Gateways, Presenters)
- `L₃` = Framework & Drivers Layer (DB, HTTP, External APIs)

### Dependency Rule
```
Inbound Dependency: L₃ → L₂ → L₁ → L₀
Outbound Dependency: L₀ ← (Port P), L₃ → (Adapter A) implements P
```

### Image Inverter Layer Mapping

**L₀: Domain Layer**
```
src/main/java/backend/domain/
    ├── entities/
    │   ├── Image
    │   ├── ProcessingJob
    │   └── InversionResult
    ├── value_objects/
    │   ├── ImageData
    │   └── ProcessingMetadata
    ├── services/
    │   ├── ImageInversionService
    │   └── ValidationService
    └── repositories/
        ├── ImageRepository (interface)
        └── ProcessingJobRepository (interface)
```

**L₁: Application Layer**
```
src/main/java/backend/services/
    ├── ImageService (Use Case: InvertImage)
    ├── ProcessingService (Use Case: ScheduleProcessing)
    └── dto/
        ├── ImageInvertRequest
        ├── ImageInvertResponse
        └── ProcessingStatusDTO
```

**L₂: Interface Adapter Layer**
```
src/main/java/backend/controllers/
    ├── ImageController (REST endpoints)
    ├── AuthController (REST endpoints)
    └── gateways/
        ├── ImageRepositoryAdapter
        └── AuthGateway

src/main/java/backend/entities/gui/
    ├── MainFrame (Presentation)
    └── SwingImageClient (GUI Adapter)
```

**L₃: Framework & Drivers**
```
src/main/java/backend/
    ├── processor/
    │   ├── AwtImageProcessor (Framework: AWT)
    │   └── ImageProcessor (Framework: Java Image API)
    └── worker/
        └── ImageProcessingWorker (Framework: Swing Worker)

External:
    ├── Database (JPA/Hibernate)
    ├── REST Framework (Spring Boot)
    └── UI Framework (Swing)
```

---

## 4. Computer Vision System Logic

### Functions and Operations

**Image Recognition:**
```
recognize: Image → ObjectSet
recognize(image) = {object₁, object₂, ..., objectₙ}
  where each object = (type, confidence, bbox)
```

**Image Processing:**
```
process: Image × ProcessingAlgorithm → ProcessedImage
invert: Image → InvertedImage
  ∀ pixel(x,y) ∈ Image:
    inverted_pixel(x,y) = (255 - R, 255 - G, 255 - B, A)
```

**Validation:**
```
validate: Image → Boolean
validate(image) = {
    width ≥ MIN_WIDTH ∧
    height ≥ MIN_HEIGHT ∧
    format ∈ {PNG, JPG, JPEG, BMP} ∧
    colorSpace ∈ {RGB, RGBA, GRAYSCALE}
}
```

**Event Registration:**
```
register: Object × Event × Timestamp → Database
where Event = {source, type, payload, timestamp}
```

**Tracking & State Management:**
```
track: Image × State × Time → StateTransition
StateTransition: PENDING → PROCESSING → COMPLETED | FAILED
```

---

## 5. Type System & Generics

### Type Notation
```
if componentTypeOf(collection) = classOf(T)
then typeOf(collection) = List<T>

Example:
    List<Image> images → componentTypeOf(images) = Image
    List<ProcessingJob> jobs → componentTypeOf(jobs) = ProcessingJob
```

### Generic Constraints
```
Repository<T extends Entity> {
    save(entity: T) → void
    findById(id: UUID) → T
    findAll() → List<T>
}

Service<A extends Aggregate> {
    process(aggregate: A) → Result<A>
}
```

### Image Inverter Type Safety
```
ImageRepository extends Repository<Image>
ProcessingJobRepository extends Repository<ProcessingJob>

ResponseWrapper<T> {
    success: Boolean
    data: T
    errors: List<ValidationError>
}

Example Usage:
    ResponseWrapper<ImageInvertResponse> response
    ResponseWrapper<List<ImageDTO>> imageList
```

---

## 6. Service Implementation Pattern

### Service Interface Contract
```
interface ImageProcessingService {
    invertImage(imageData: ImageData) → Result<InversionResult>
    validateImage(imageData: ImageData) → Result<ValidationReport>
    scheduleProcessing(jobRequest: ProcessingRequest) → Result<ProcessingJob>
    getProcessingStatus(jobId: UUID) → Result<ProcessingStatusDTO>
}
```

### Implementation Mapping
```
∀ method ∈ Contract:
    ∃ implementation ∈ ServiceImpl {
        precondition: validate inputs
        action: perform domain logic
        postcondition: return result
        exception: handle domain errors
    }
```

### Image Inverter Service Implementation
```
ImageServiceImpl implements ImageService {
    ✓ invertImage: validates → processors → repositories → returns response
    ✓ getStatus: queries repository → returns current state
    ✓ processImage: delegates → worker thread → async completion
}
```

---

## 7. Event-Driven Architecture

### Event Structure
```
DomainEvent {
    id: UUID
    type: String (ImageInvertedEvent, ProcessingFailedEvent, etc.)
    source: String (ImageProcessingBC, AuthenticationBC)
    payload: Map<String, Any>
    timestamp: Instant
    aggregateId: UUID
}
```

### Event Flow
```
Event {
    generated by → Domain Service
    published to → Event Handler
    handled by → Application Service or Domain Service
    result → Side Effects (DB update, Notification, Next Event)
}
```

### Image Inverter Events
```
ImageInvertedEvent {
    aggregateId: imageId
    payload: { originalImageId, invertedImageId, duration_ms }
    timestamp: now()
}

ProcessingScheduledEvent {
    aggregateId: jobId
    payload: { jobId, priority, scheduledTime }
    timestamp: now()
}

ProcessingFailedEvent {
    aggregateId: jobId
    payload: { jobId, errorMessage, errorCode }
    timestamp: now()
}
```

### Event Handler Pattern
```
@EventListener
onImageInverted(event: ImageInvertedEvent) {
    1. Update repository with result
    2. Send notification to user
    3. Publish completion event
    4. Update metrics/statistics
}
```

---

## 8. Data Flow & State Machines

### Image Processing State Machine
```
[PENDING] 
    → (submit) → [VALIDATION]
    
[VALIDATION]
    → (valid) → [QUEUED]
    → (invalid) → [FAILED] (emit ValidationError)
    
[QUEUED]
    → (worker available) → [PROCESSING]
    
[PROCESSING]
    → (success) → [COMPLETED] (emit ImageInvertedEvent)
    → (error) → [FAILED] (emit ProcessingFailedEvent)
    
[COMPLETED]
    → (archive) → [ARCHIVED]
    
[FAILED]
    → (retry) → [PENDING]
    → (max retries) → [ARCHIVED]
```

### Type Signatures with State
```
stateTransition: (Image, State, Action) → (Image, State')

Example:
    stateTransition(img, PENDING, SUBMIT) 
        → (img, VALIDATION)
    
    stateTransition(img, PROCESSING, SUCCESS)
        → (img, COMPLETED)
```

---

## 9. REST API as Open Host Service (OHS)

### OHS Definition
```
OHS: ImageProcessingBC → REST API → Consumers
```

### REST Endpoint Mapping to Domain
```
POST /api/images/invert
    → Application Service: ImageService.invertImage()
    → Domain Service: ImageInversionService.process()
    
GET /api/images/{id}
    → Repository: ImageRepository.findById()
    
GET /api/processing/{jobId}/status
    → Repository: ProcessingJobRepository.findById()
    → Return: ProcessingStatusDTO (ACL translation)
    
GET /api/processing/statistics
    → Query Service: Report generation from Events
```

### DTO as Anti-Corruption Layer (ACL)
```
REST Input (DTO) → ACL Translation → Domain Entity
RequestDTO {
    imageBase64: String,
    format: String
}
    ↓ (ACL.translate)
Image Entity {
    id: UUID,
    data: ImageData,
    state: PENDING,
    createdAt: Instant
}

Domain Entity → ACL Translation → REST Output (DTO)
```

---

## 10. Integration Points & Consistency

### Across-Layer Communication Pattern
```
REST Request (L₂)
    ↓ (DTO → Domain Model conversion)
Application Service (L₁)
    ↓ (coordinates domain logic)
Domain Service (L₀)
    ↓ (business logic)
Repository (L₀)
    ↓ (adapter interface)
Database Adapter (L₃)
    ↓ (database operation)
Result → Response (DTO conversion) → HTTP Response (L₂)
```

### Consistency Boundaries
```
Within Aggregate: ACID transactions on the root
Across Aggregates: Eventually consistent via events
Across Bounded Contexts: Via ACL + Event Bus
```

---

## 11. Metrics & Observability

### Measurable Properties
```
ProcessingMetrics {
    totalProcessed: Integer
    successCount: Integer
    failureCount: Integer
    avgProcessingTime_ms: Double
    p99ProcessingTime_ms: Double
}

Calculation:
    avgTime = Σ(execution_time) / count
    successRate = successCount / totalProcessed
```

### Logging Points
```
L₀ (Domain): Domain events logged
L₁ (Application): Use case entry/exit logged
L₂ (Interface): HTTP request/response logged
L₃ (Framework): Database queries logged
```

---

## References

- Evans, E. (2003). *Domain-Driven Design: Tackling Complexity in the Heart of Software*
- Martin, R. C. (2017). *Clean Architecture: A Craftsman's Guide*
- Alistair Cockburn's *Hexagonal Architecture*
- CQRS & Event Sourcing Patterns

---

**Last Updated:** December 18, 2025
**Version:** 1.0
**Status:** Active Reference Documentation
