# Architecture Visualization

## Complete System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         EXTERNAL WORLD                              │
│  ┌────────────┬────────────┬────────────┬────────────┐              │
│  │  Web UI    │  Mobile    │  Desktop   │ Third-party│              │
│  │  (React)   │   Apps     │   Apps     │  Services  │              │
│  └────────────┴────────────┴────────────┴────────────┘              │
└─────────────────────────────────────────────────────────────────────┘
                            ↓ HTTP/JSON
┌─────────────────────────────────────────────────────────────────────┐
│ L₂: INTERFACE ADAPTER LAYER (backend/controllers)                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │         ImageController                                      │  │
│  │  ┌─────────────┐  ┌──────────┐  ┌──────────────┐           │  │
│  │  │POST /invert │  │GET /id   │  │GET /status   │           │  │
│  │  └─────────────┘  └──────────┘  └──────────────┘           │  │
│  └──────────────────────────────────────────────────────────────┘  │
│           ↓ DTOs ↓ Validation ↓ Exception Handling                  │
└─────────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────────┐
│ L₁: APPLICATION LAYER (backend/services + backend/dto)              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │              ImageService (Use Cases)                       │  │
│  │  - invertImage()                                            │  │
│  │  - getProcessingStatus()                                    │  │
│  │  - getStatistics()                                          │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                            ↓                                          │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  ACL: DTO ↔ Domain Entity Conversion                         │  │
│  │  - ImageInvertRequest  → Image + ImageData                  │  │
│  │  - Image + InversionResult → ImageInvertResponse            │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                            ↓                                          │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │              Event Handlers (Async)                          │  │
│  │  - ImageInvertedEventHandler                                │  │
│  │  - ProcessingFailedEventHandler                             │  │
│  │  - ProcessingScheduledEventHandler                          │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
                    ↓ Coordinates ↓ Publishes Events
┌─────────────────────────────────────────────────────────────────────┐
│ L₀: DOMAIN LAYER (backend/domain)                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  AGGREGATES                                                 │  │
│  │  ┌────────────────────────────────────────────────────────┐ │  │
│  │  │ ImageProcessingAggregate                               │ │  │
│  │  │  ├─ Root: Image (Entity)                               │ │  │
│  │  │  │  ├─ Identity: UUID                                  │ │  │
│  │  │  │  ├─ State: PENDING|PROCESSING|COMPLETED|FAILED     │ │  │
│  │  │  │  └─ Lifecycle: created → modified → archived        │ │  │
│  │  │  │                                                      │ │  │
│  │  │  ├─ Child: ImageData (ValueObject)                     │ │  │
│  │  │  │  ├─ pixels: byte[]                                  │ │  │
│  │  │  │  ├─ width, height: int                              │ │  │
│  │  │  │  ├─ format: PNG|JPG|BMP                             │ │  │
│  │  │  │  └─ immutable & compared by value                   │ │  │
│  │  │  │                                                      │ │  │
│  │  │  └─ Child: InversionResult (ValueObject)               │ │  │
│  │  │     ├─ invertedPixels: byte[]                          │ │  │
│  │  │     ├─ processingTime_ms: long                         │ │  │
│  │  │     └─ immutable & compared by value                   │ │  │
│  │  │                                                         │ │  │
│  │  │  Invariants:                                            │ │  │
│  │  │  ✓ Image must have valid ImageData                     │ │  │
│  │  │  ✓ Cannot be processed twice                           │ │  │
│  │  │  ✓ Result only exists after completion                 │ │  │
│  │  │  ✓ State follows state machine                         │ │  │
│  │  └────────────────────────────────────────────────────────┘ │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  DOMAIN SERVICES (Stateless)                               │  │
│  │  ┌──────────────────────────────────────────────────────┐  │  │
│  │  │ ImageInversionService                               │  │  │
│  │  │  - invert(ImageData) → InversionResult             │  │  │
│  │  │  - validate(ImageData) → ValidationReport          │  │  │
│  │  │                                                      │  │  │
│  │  │ Contains business logic:                            │  │  │
│  │  │  ✓ Pixel inversion algorithm                        │  │  │
│  │  │  ✓ Input validation rules                           │  │  │
│  │  │  ✓ Event publishing on completion                  │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  REPOSITORIES (Ports/Interfaces)                           │  │
│  │  ┌──────────────────────────────────────────────────────┐  │  │
│  │  │ ImageRepository                                     │  │  │
│  │  │  - save(Image): void                               │  │  │
│  │  │  - findById(UUID): Image                           │  │  │
│  │  │  - findByStatus(State): List<Image>               │  │  │
│  │  │  - delete(UUID): void                             │  │  │
│  │  │                                                      │  │  │
│  │  │ Definition: Abstraction, no implementation          │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  DOMAIN EVENTS                                              │  │
│  │  ┌──────────────────┬──────────────────┬────────────────┐  │  │
│  │  │ImageInvertedEvent│ProcessingFailed │ProcessingQueued│  │  │
│  │  │- id: UUID        │- id: UUID       │- id: UUID      │  │  │
│  │  │- timestamp       │- errorCode      │- timestamp     │  │  │
│  │  │- duration_ms     │- errorMessage   │- jobId         │  │  │
│  │  └──────────────────┴──────────────────┴────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  SPECIFICATIONS (Business Rules)                            │  │
│  │  - ValidImageSpecification                                 │  │
│  │  - SmallImageSpecification                                 │  │
│  │  - ComposableSpecification                                 │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
                    ↓ Implementation Dependency Injection
┌─────────────────────────────────────────────────────────────────────┐
│ L₃: FRAMEWORK & DRIVERS (Infrastructure)                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  REPOSITORY ADAPTERS (Implementations of L₀ Ports)         │  │
│  │  ┌──────────────────────────────────────────────────────┐  │  │
│  │  │ ImageRepositoryAdapter                              │  │  │
│  │  │  implements ImageRepository                         │  │  │
│  │  │  - save(Image) → ImageJpaRepository.save()         │  │  │
│  │  │  - findById(UUID) → ImageJpaRepository.findById()  │  │  │
│  │  │  - Mapper: Image ↔ ImageEntity                     │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  PROCESSORS (Framework-Specific Logic)                      │  │
│  │  ┌──────────────────────────────────────────────────────┐  │  │
│  │  │ AwtImageProcessor                                   │  │  │
│  │  │  - invertPixels(byte[]) → byte[]                   │  │  │
│  │  │  - Uses AWT & BufferedImage                         │  │  │
│  │  │                                                      │  │  │
│  │  │ ImageProcessor (java.awt.image wrapper)            │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  JPA/HIBERNATE                                              │  │
│  │  ┌──────────────────────────────────────────────────────┐  │  │
│  │  │ ImageEntity (JPA/Hibernate mapping)                 │  │  │
│  │  │  @Entity                                             │  │  │
│  │  │  @Table("images")                                   │  │  │
│  │  │  - id: UUID                                         │  │  │
│  │  │  - pixels: byte[]                                  │  │  │
│  │  │  - width, height, format, colorSpace: String      │  │  │
│  │  │  - state: String                                   │  │  │
│  │  │  - invertedPixels, processingTime: (optional)      │  │  │
│  │  │                                                      │  │  │
│  │  │ ImageJpaRepository                                  │  │  │
│  │  │  extends JpaRepository<ImageEntity, UUID>           │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  SPRING BOOT CONFIGURATION                                  │  │
│  │  ┌──────────────────────────────────────────────────────┐  │  │
│  │  │ BeansConfiguration                                  │  │  │
│  │  │ EventListenerConfiguration                          │  │  │
│  │  │ PersistenceConfiguration                            │  │  │
│  │  │ SwaggerConfiguration                                │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  DATABASE                                                   │  │
│  │  ┌──────────────────────────────────────────────────────┐  │  │
│  │  │ PostgreSQL / H2 (Dev)                               │  │  │
│  │  │ Table: images                                        │  │  │
│  │  │ - id (UUID, PK)                                     │  │  │
│  │  │ - pixels (bytea)                                    │  │  │
│  │  │ - metadata (width, height, format, colorSpace)     │  │  │
│  │  │ - state (VARCHAR)                                   │  │  │
│  │  │ - result (inverted_pixels, processing_time)        │  │  │
│  │  │ - timestamps (created_at, modified_at)             │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow: Image Inversion Request

```
User/Client                   Controller              Service Layer      Domain Layer         Framework
     │                             │                       │                  │                 │
     │────HTTP POST────────────────→│                       │                  │                 │
     │  /api/v1/images/invert       │                       │                  │                 │
     │  ImageInvertRequest.json      │                       │                  │                 │
     │                              │                       │                  │                 │
     │                              │──Deserialize────────→│                  │                 │
     │                              │  Validate @Valid     │                  │                 │
     │                              │                      │                  │                 │
     │                              │──ACL Transform────→  │                  │                 │
     │                              │  DTO → ImageData   │                  │                 │
     │                              │                      │                  │                 │
     │                              │──Call Service────────→│                  │                 │
     │                              │  imageService.invert()                  │                 │
     │                              │                      │                  │                 │
     │                              │                      │──Create────────→ Image Entity     │
     │                              │                      │                  │                 │
     │                              │                      │──Save─────────────────────────────→│
     │                              │                      │  ImageRepository.save()           │
     │                              │                      │                  │    JPA Persist │
     │                              │                      │                  │   to Database  │
     │                              │                      │                  │                 │
     │                              │                      │──Domain Service──────────────────→│
     │                              │                      │  ImageInversionService          │
     │                              │                      │  .invert()                       │
     │                              │                      │                  │    AWT Process │
     │                              │                      │                  │    Pixels      │
     │                              │                      │                  │                 │
     │                              │                      │  InversionResult ←────Return─────│
     │                              │                      │  (inverted, time)                │
     │                              │                      │                  │                 │
     │                              │                      │──Update────────→ Image.setResult()
     │                              │                      │  Image           │                 │
     │                              │                      │                  │                 │
     │                              │                      │──Save────────────────────────────→│
     │                              │                      │  Updated Image    JPA Update      │
     │                              │                      │                  │                 │
     │                              │                      │──Publish Event────────────────────│
     │                              │                      │  ImageInvertedEvent              │
     │                              │                      │                  │                 │
     │                              │◄─ACL Response────────│                  │                 │
     │                              │  Image →ImageInvertResponse            │                 │
     │                              │                      │                  │                 │
     │◄─HTTP 200 OK─────────────────│                       │                  │                 │
     │  ApiResponse<DTO>             │                       │                  │                 │
     │  {success:true, data:{...}}   │                       │                  │                 │
     │                              │                       │                  │                 │

Event Handlers (Async - Different Thread Pool)
     │
     ├──ImageInvertedEventHandler────→ MetricsService (record success)
     ├──ImageInvertedEventHandler────→ NotificationService (notify user)
     └──ImageInvertedEventHandler────→ PostProcessingService (thumbnails, etc.)
```

---

## State Machine

```
                    ┌─────────────────────────────────┐
                    │        PENDING                  │
                    │   (Initial State)               │
                    │                                 │
                    │ - Created by user               │
                    │ - Waiting for validation        │
                    └──────────────┬──────────────────┘
                                   │ submit()
                                   ↓
                    ┌─────────────────────────────────┐
                    │      VALIDATION                 │
                    │                                 │
                    │ - Check image format            │
                    │ - Check dimensions              │
                    │ - Check file size               │
                    └──────────────┬──────────────────┘
                                   │
                    ┌──────────────┘ └──────────────┐
                    │ (valid)                │ (invalid)
                    ↓                        ↓
      ┌─────────────────────────┐  ┌──────────────────────┐
      │      QUEUED             │  │    FAILED            │
      │                         │  │                      │
      │ - In processing queue   │  │ - ValidationError    │
      │ - Awaiting worker       │  │ - Stored in archive  │
      │ - Priority ordering     │  │ - Notify user        │
      └──────────────┬──────────┘  └──────────────────────┘
                     │ (worker available)       ↑
                     ↓                          │
      ┌─────────────────────────┐              │
      │    PROCESSING           │              │
      │                         │              │
      │ - Inverting pixels      │              │
      │ - Computing metrics     │              │
      │ - Active operation      │              │
      └──────────────┬──────────┘              │
                     │                          │
        ┌────────────┘ └────────────┐          │
        │ (success)         │(error) │         │
        ↓                   ↓        │         │
 ┌──────────────┐  ┌────────────────────────┐ │
 │  COMPLETED   │  │  FAILED                │─┘
 │              │  │                        │
 │ - Result OK  │  │ - ProcessingError      │
 │ - Saved DB   │  │ - Retry logic initiated│
 │ - Notify OK  │  │ - Error logged         │
 │ - Event pub  │  │ - Notify user          │
 └──────┬───────┘  └────────────────────────┘
        │ (archive)
        ↓
 ┌──────────────┐
 │   ARCHIVED   │
 │              │
 │ - Moved to   │
 │   cold store │
 │ - No queries │
 │ - Deletable  │
 └──────────────┘
```

---

## Dependency Injection Graph

```
Application Context
│
├─ L₃: Framework Services
│  ├─ ImageProcessor (AWT impl)
│  ├─ ImageJpaRepository (Spring Data)
│  └─ JPA EntityManager
│
├─ L₀: Domain Services
│  └─ ImageInversionService ←── depends on ImageProcessor
│
├─ L₁: Application Services
│  ├─ ImageService ←── depends on
│  │  ├─ ImageRepository (port)
│  │  ├─ ImageInversionService (domain service)
│  │  └─ ApplicationEventPublisher
│  │
│  └─ Event Handlers
│     ├─ ImageInvertedEventHandler ←── depends on
│     │  ├─ ImageRepository
│     │  ├─ NotificationService
│     │  └─ MetricsService
│     │
│     ├─ ProcessingFailedEventHandler
│     └─ ProcessingScheduledEventHandler
│
├─ L₂: Controllers
│  └─ ImageController ←── depends on
│     ├─ ImageService
│     └─ DTOConverter
│
├─ L₃: Repository Adapters
│  └─ ImageRepositoryAdapter ←── depends on
│     │   implements ImageRepository (L₀ port)
│     ├─ ImageJpaRepository (Spring Data)
│     └─ ImageMapper
│
└─ Configuration
   ├─ BeansConfiguration
   ├─ EventListenerConfiguration
   ├─ PersistenceConfiguration
   └─ SwaggerConfiguration
```

---

## Bounded Contexts

```
┌──────────────────────────────────────────────────────────────────┐
│                    Image Inverter System                         │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │   Image Processing Context (Core Domain)                  │  │
│  │                                                            │  │
│  │  Entities:                                                │  │
│  │  - Image (with inversion state machine)                  │  │
│  │  - ProcessingJob                                         │  │
│  │                                                            │  │
│  │  ValueObjects:                                            │  │
│  │  - ImageData (pixels, dimensions)                        │  │
│  │  - InversionResult                                       │  │
│  │  - ProcessingMetadata                                    │  │
│  │                                                            │  │
│  │  Services:                                                │  │
│  │  - ImageInversionService                                 │  │
│  │  - ValidationService                                     │  │
│  │                                                            │  │
│  │  Repositories:                                            │  │
│  │  - ImageRepository                                       │  │
│  │  - ProcessingJobRepository                               │  │
│  │                                                            │  │
│  │  Events:                                                  │  │
│  │  - ImageInvertedEvent                                    │  │
│  │  - ProcessingFailedEvent                                 │  │
│  │  - ProcessingScheduledEvent                              │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────┬──────────────────────────────────┐  │
│  │ REST API Context         │ GUI Context (Legacy)            │  │
│  │ (Open Host Service)      │                                 │  │
│  │                          │ Entities:                       │  │
│  │ Services:               │ - MainFrame                     │  │
│  │ - RestConverter          │ - UIState                       │  │
│  │ - ErrorHandler           │                                 │  │
│  │                          │ Services:                       │  │
│  │ Integration:             │ - RenderService                 │  │
│  │ - Clients consume        │ - EventBroadcaster              │  │
│  │  Image Processing via    │                                 │  │
│  │  REST API                │ Integration:                    │  │
│  │                          │ - Swing client for legacy      │  │
│  │                          │   users                        │  │
│  └──────────────────────────┴──────────────────────────────────┘  │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │   Authentication Context (Optional)                        │  │
│  │                                                            │  │
│  │  When implemented:                                         │  │
│  │  - User entities with credentials                        │  │
│  │  - ACL layer with Image Processing Context              │  │
│  │  - Token validation on REST endpoints                   │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

---

## Event Flow

```
Domain Service          Application Service        Event Bus          Handlers
    │                         │                        │                │
    │─ invert()               │                        │                │
    │  ✓ success              │                        │                │
    │◄─ InversionResult ──────│                        │                │
    │                         │                        │                │
    │                    mark completed()              │                │
    │                    save to DB                    │                │
    │                         │                        │                │
    │                    publish event◄─ ImageInvertedEvent            │
    │                         │              │         │                │
    │                         │              │─────────→────────────┐  │
    │                         │              │    subscribe     (async)│
    │                         │              │         │          ┌──┴──────────┐
    │                         │              │         │   ImageInvertedEventHandler
    │                         │              │         │          │
    │                         │              │         │   ├─ Update metrics
    │                         │              │         │   ├─ Send notification
    │                         │              │         │   └─ Post-process
    │                         │              │         │
    │                         │              │    ProcessingFailedEventHandler
    │─ invert()               │              │         │
    │  ✗ error                │              │         │   ├─ Log error
    │                         │              │         │   ├─ Update status
    │◄─ throws Exception ─────│              │         │   └─ Notify user
    │                         │              │         │
    │                    catch & mark failed()        │
    │                    save to DB                    │
    │                    publish event◄─ ProcessingFailedEvent
    │                         │              │         │
    │                         │              │─────────→────────────┐
    │                         │              │                      │
    │                         │              │        ProcessingFailedEventHandler
    │                         │              │              │
    │                         │              │         ├─ Log failure
    │                         │              │         ├─ Update DB
    │                         │              │         └─ Alert user
```

---

**Last Updated:** December 18, 2025  
**Version:** 1.0  
**Status:** Complete & Visual
