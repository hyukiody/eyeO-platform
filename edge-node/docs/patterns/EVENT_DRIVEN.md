# Event-Driven Architecture Guide

## Overview

Event-Driven Architecture allows loose coupling between components through asynchronous event publishing and handling.

---

## 1. Domain Events

### Definition
Significant events that occur in the domain, recorded as facts.

### Event Structure

**Location:** `backend/domain/events/DomainEvent.java`

```java
public abstract class DomainEvent {
    private final UUID aggregateId;
    private final UUID eventId;
    private final Instant occurredAt;
    private final String eventType;
    
    protected DomainEvent(UUID aggregateId, String eventType) {
        this.aggregateId = Objects.requireNonNull(aggregateId);
        this.eventId = UUID.randomUUID();
        this.occurredAt = Instant.now();
        this.eventType = eventType;
    }
    
    public UUID getAggregateId() { return aggregateId; }
    public UUID getEventId() { return eventId; }
    public Instant getOccurredAt() { return occurredAt; }
    public String getEventType() { return eventType; }
}
```

---

## 2. Image Processing Events

### ImageInvertedEvent (Success)

**Location:** `backend/domain/events/ImageInvertedEvent.java`

```java
public class ImageInvertedEvent extends DomainEvent {
    private final UUID invertedImageId;
    private final long processingTime_ms;
    private final String originalFormat;
    
    public ImageInvertedEvent(
        UUID imageId,
        UUID invertedImageId,
        long processingTime_ms,
        String originalFormat
    ) {
        super(imageId, "ImageInverted");
        this.invertedImageId = Objects.requireNonNull(invertedImageId);
        this.processingTime_ms = processingTime_ms;
        this.originalFormat = originalFormat;
    }
    
    public UUID getInvertedImageId() { return invertedImageId; }
    public long getProcessingTime_ms() { return processingTime_ms; }
    public String getOriginalFormat() { return originalFormat; }
}
```

### ProcessingFailedEvent (Error)

```java
public class ProcessingFailedEvent extends DomainEvent {
    private final String errorMessage;
    private final String errorCode;
    private final Exception cause;
    
    public ProcessingFailedEvent(
        UUID imageId,
        String errorCode,
        String errorMessage,
        Exception cause
    ) {
        super(imageId, "ProcessingFailed");
        this.errorCode = Objects.requireNonNull(errorCode);
        this.errorMessage = Objects.requireNonNull(errorMessage);
        this.cause = cause;
    }
    
    public String getErrorMessage() { return errorMessage; }
    public String getErrorCode() { return errorCode; }
    public Exception getCause() { return cause; }
}
```

### ProcessingScheduledEvent

```java
public class ProcessingScheduledEvent extends DomainEvent {
    private final UUID jobId;
    private final int priority;
    private final Instant scheduledTime;
    
    public ProcessingScheduledEvent(
        UUID imageId,
        UUID jobId,
        int priority,
        Instant scheduledTime
    ) {
        super(imageId, "ProcessingScheduled");
        this.jobId = Objects.requireNonNull(jobId);
        this.priority = priority;
        this.scheduledTime = Objects.requireNonNull(scheduledTime);
    }
    
    public UUID getJobId() { return jobId; }
    public int getPriority() { return priority; }
    public Instant getScheduledTime() { return scheduledTime; }
}
```

---

## 3. Event Publishing

### Publishing from Domain Service

**Location:** `backend/domain/services/ImageInversionService.java`

```java
@Service
public class ImageInversionServiceImpl implements ImageInversionService {
    
    private final ImageProcessor processor;
    private final ApplicationEventPublisher eventPublisher;
    
    @Override
    public InversionResult invert(ImageData imageData, UUID imageId) {
        try {
            long startTime = System.currentTimeMillis();
            byte[] inverted = processor.invertPixels(imageData.getPixels());
            long duration = System.currentTimeMillis() - startTime;
            
            InversionResult result = new InversionResult(inverted, duration);
            
            // Publish success event
            ImageInvertedEvent event = new ImageInvertedEvent(
                imageId,
                UUID.randomUUID(),
                duration,
                imageData.getFormat().name()
            );
            eventPublisher.publishEvent(event);
            
            return result;
            
        } catch (Exception e) {
            // Publish failure event
            ProcessingFailedEvent event = new ProcessingFailedEvent(
                imageId,
                "INVERSION_ERROR",
                e.getMessage(),
                e
            );
            eventPublisher.publishEvent(event);
            throw new ProcessingException(e);
        }
    }
}
```

### Publishing from Application Service

**Location:** `backend/services/ImageService.java`

```java
@Service
public class ImageService {
    
    private final ImageRepository repository;
    private final ImageInversionService inversionService;
    private final ApplicationEventPublisher eventPublisher;
    
    @Transactional
    public ImageInvertResponse invertImage(ImageInvertRequest request) {
        // 1. Create domain aggregate
        ImageData imageData = createImageData(request);
        Image image = Image.create(imageData);
        
        // 2. Mark as processing
        image.markProcessing();
        repository.save(image);
        
        // 3. Publish scheduled event
        ProcessingScheduledEvent scheduledEvent = 
            new ProcessingScheduledEvent(
                image.getId(),
                UUID.randomUUID(),
                1,
                Instant.now()
            );
        eventPublisher.publishEvent(scheduledEvent);
        
        // 4. Perform inversion
        InversionResult result = inversionService.invert(imageData, image.getId());
        
        // 5. Update aggregate
        image.markCompleted(result);
        repository.save(image);
        
        // Note: ImageInvertedEvent published by domain service
        
        return toResponse(image);
    }
}
```

---

## 4. Event Handlers

### Application Service Event Handler

**Location:** `backend/services/handlers/ImageInvertedEventHandler.java`

```java
@Component
public class ImageInvertedEventHandler {
    
    private final ImageRepository repository;
    private final NotificationService notificationService;
    private final MetricsService metricsService;
    private static final Logger logger = 
        LoggerFactory.getLogger(ImageInvertedEventHandler.class);
    
    @EventListener
    public void onImageInverted(ImageInvertedEvent event) {
        logger.info("Processing ImageInvertedEvent: {}", event.getAggregateId());
        
        try {
            // 1. Update statistics
            metricsService.recordSuccess(event.getProcessingTime_ms());
            
            // 2. Send notification
            notificationService.notifyCompletion(event.getAggregateId());
            
            // 3. Trigger post-processing if needed
            Image image = repository.findById(event.getAggregateId());
            performPostProcessing(image);
            
            logger.info("ImageInvertedEvent processed successfully");
            
        } catch (Exception e) {
            logger.error("Error processing ImageInvertedEvent", e);
            // Implement retry logic or dead-letter handling
        }
    }
    
    private void performPostProcessing(Image image) {
        // Additional logic after successful inversion
        // E.g., thumbnail generation, caching, indexing
    }
}
```

### Processing Failed Event Handler

```java
@Component
public class ProcessingFailedEventHandler {
    
    private final ImageRepository repository;
    private final NotificationService notificationService;
    private final MetricsService metricsService;
    private static final Logger logger = 
        LoggerFactory.getLogger(ProcessingFailedEventHandler.class);
    
    @EventListener
    public void onProcessingFailed(ProcessingFailedEvent event) {
        logger.warn("Processing failed for image: {}", 
                   event.getAggregateId());
        
        try {
            // 1. Update metrics
            metricsService.recordFailure(event.getErrorCode());
            
            // 2. Update image status
            Image image = repository.findById(event.getAggregateId());
            image.markFailed(event.getErrorMessage());
            repository.save(image);
            
            // 3. Notify user of failure
            notificationService.notifyFailure(
                event.getAggregateId(),
                event.getErrorCode(),
                event.getErrorMessage()
            );
            
            // 4. Log for analysis
            logErrorForAnalysis(event);
            
        } catch (Exception e) {
            logger.error("Error handling ProcessingFailedEvent", e);
        }
    }
    
    private void logErrorForAnalysis(ProcessingFailedEvent event) {
        // Send to error tracking service (e.g., Sentry, DataDog)
    }
}
```

### Scheduled Event Handler

```java
@Component
public class ProcessingScheduledEventHandler {
    
    private final ProcessingQueue queue;
    private static final Logger logger = 
        LoggerFactory.getLogger(ProcessingScheduledEventHandler.class);
    
    @EventListener
    public void onProcessingScheduled(ProcessingScheduledEvent event) {
        logger.debug("Enqueuing job: {}", event.getJobId());
        
        try {
            queue.enqueue(
                new ProcessingJob(
                    event.getJobId(),
                    event.getAggregateId(),
                    event.getPriority(),
                    event.getScheduledTime()
                )
            );
            logger.info("Job enqueued: {}", event.getJobId());
        } catch (Exception e) {
            logger.error("Error enqueuing job", e);
        }
    }
}
```

---

## 5. Event Listener Configuration

**Location:** `backend/config/EventListenerConfiguration.java`

```java
@Configuration
public class EventListenerConfiguration {
    
    /**
     * Enable Spring's event publishing mechanism.
     * Asynchronous event publishing for non-blocking operations.
     */
    @Bean
    public ApplicationEventMulticaster applicationEventMulticaster() {
        SimpleApplicationEventMulticaster multicaster = 
            new SimpleApplicationEventMulticaster();
        multicaster.setTaskExecutor(eventExecutor());
        return multicaster;
    }
    
    /**
     * Thread pool for async event handling.
     */
    @Bean(name = "eventExecutor")
    public Executor eventExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(5);
        executor.setMaxPoolSize(10);
        executor.setQueueCapacity(100);
        executor.setThreadNamePrefix("event-handler-");
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(60);
        executor.initialize();
        return executor;
    }
}
```

---

## 6. Synchronous vs Asynchronous Events

### Synchronous (Blocking)

```java
@EventListener
public void handleImmediately(ImageInvertedEvent event) {
    // Executes in same thread
    // Blocks controller response
    // Use for: critical operations, data consistency
}
```

### Asynchronous (Non-Blocking)

```java
@EventListener
@Async("eventExecutor")
public void handleAsync(ImageInvertedEvent event) {
    // Executes in thread pool
    // Does NOT block controller response
    // Use for: notifications, analytics, non-critical updates
}
```

---

## 7. Event Sourcing Pattern (Optional)

### Event Store

```java
public interface EventStore {
    void append(DomainEvent event);
    List<DomainEvent> getEventsForAggregate(UUID aggregateId);
    void replay(UUID aggregateId, Consumer<DomainEvent> handler);
}

@Repository
public class EventStoreAdapter implements EventStore {
    
    private final EventJpaRepository jpaRepository;
    
    @Override
    public void append(DomainEvent event) {
        EventEntity entity = new EventEntity(
            event.getEventId(),
            event.getAggregateId(),
            event.getEventType(),
            serializeEvent(event),
            event.getOccurredAt()
        );
        jpaRepository.save(entity);
    }
    
    @Override
    public List<DomainEvent> getEventsForAggregate(UUID aggregateId) {
        return jpaRepository.findByAggregateIdOrderByOccurredAtAsc(aggregateId)
            .stream()
            .map(this::deserializeEvent)
            .collect(Collectors.toList());
    }
}
```

---

## 8. Event Bus Pattern (For External Events)

### Publish to Message Broker

```java
@Component
public class ExternalEventPublisher {
    
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;
    
    public void publishToKafka(DomainEvent event) 
        throws JsonProcessingException {
        
        String topic = determineTopic(event.getEventType());
        String payload = objectMapper.writeValueAsString(event);
        
        kafkaTemplate.send(topic, event.getAggregateId().toString(), payload)
            .addCallback(
                success -> logger.info("Event published to Kafka"),
                failure -> logger.error("Failed to publish event", failure)
            );
    }
    
    private String determineTopic(String eventType) {
        return switch (eventType) {
            case "ImageInverted" -> "image-inverted-events";
            case "ProcessingFailed" -> "processing-failed-events";
            case "ProcessingScheduled" -> "processing-scheduled-events";
            default -> "domain-events";
        };
    }
}
```

---

## 9. Testing Events

### Unit Testing Event Handlers

**Location:** `src/test/java/backend/services/handlers/ImageInvertedEventHandlerTest.java`

```java
@ExtendWith(MockitoExtension.class)
public class ImageInvertedEventHandlerTest {
    
    @Mock
    private ImageRepository repository;
    
    @Mock
    private NotificationService notificationService;
    
    @Mock
    private MetricsService metricsService;
    
    @InjectMocks
    private ImageInvertedEventHandler handler;
    
    @Test
    public void shouldProcessImageInvertedEvent() {
        // Arrange
        UUID imageId = UUID.randomUUID();
        UUID invertedImageId = UUID.randomUUID();
        ImageInvertedEvent event = new ImageInvertedEvent(
            imageId, invertedImageId, 250, "PNG"
        );
        
        Image image = mock(Image.class);
        when(repository.findById(imageId)).thenReturn(image);
        
        // Act
        handler.onImageInverted(event);
        
        // Assert
        verify(metricsService).recordSuccess(250);
        verify(notificationService).notifyCompletion(imageId);
        verify(repository).findById(imageId);
    }
}
```

### Integration Testing Event Flow

```java
@SpringBootTest
public class EventFlowIntegrationTest {
    
    @Autowired
    private ApplicationEventPublisher eventPublisher;
    
    @Autowired
    private ImageRepository repository;
    
    @Autowired
    private TestEventCaptor eventCaptor;
    
    @Test
    public void shouldPublishAndHandleImageInvertedEvent() 
        throws InterruptedException {
        // Arrange
        UUID imageId = UUID.randomUUID();
        Image image = Image.create(createTestImageData());
        repository.save(image);
        
        ImageInvertedEvent event = new ImageInvertedEvent(
            imageId, UUID.randomUUID(), 150, "PNG"
        );
        
        // Act
        eventPublisher.publishEvent(event);
        
        // Assert
        assertTrue(eventCaptor.waitForEvent(
            ImageInvertedEvent.class, 
            Duration.ofSeconds(5)
        ));
        
        Image updatedImage = repository.findById(imageId);
        assertTrue(updatedImage.isCompleted());
    }
}
```

---

## Best Practices

✅ **Publish from Domain Service** - Keep domain logic in domain layer  
✅ **Handle Asynchronously** - Use @Async for non-critical operations  
✅ **Idempotent Handlers** - Can safely process same event multiple times  
✅ **Log All Events** - For audit and debugging  
✅ **Error Handling** - Implement retry and dead-letter queues  
✅ **Type Safety** - Use concrete event classes, not strings  
✅ **Testing** - Test event publishing and handling separately  

---

**Last Updated:** December 18, 2025  
**Version:** 1.0  
**Status:** Active Reference
