# DDD Patterns & Implementation Guide

## 1. Entity Pattern

### Definition
An Entity is an object with a unique identity that persists over time and can change state.

### Image Inverter: Image Entity

**Location:** `backend/domain/entities/Image.java`

```java
public class Image implements Entity<UUID> {
    private final UUID id;
    private final ImageData imageData;
    private State state;
    private final Instant createdAt;
    private Instant modifiedAt;
    private InversionResult result;
    
    private Image(UUID id, ImageData imageData) {
        this.id = Objects.requireNonNull(id);
        this.imageData = Objects.requireNonNull(imageData);
        this.state = State.PENDING;
        this.createdAt = Instant.now();
        this.modifiedAt = createdAt;
    }
    
    public static Image create(ImageData imageData) {
        return new Image(UUID.randomUUID(), imageData);
    }
    
    // Identity
    @Override
    public UUID getId() {
        return id;
    }
    
    // State changes
    public void markProcessing() {
        this.state = State.PROCESSING;
        this.modifiedAt = Instant.now();
    }
    
    public void markCompleted(InversionResult result) {
        this.result = result;
        this.state = State.COMPLETED;
        this.modifiedAt = Instant.now();
    }
    
    public void markFailed(String errorReason) {
        this.state = State.FAILED;
        this.modifiedAt = Instant.now();
    }
    
    // Lifecycle query
    public boolean isPending() { return state == State.PENDING; }
    public boolean isProcessing() { return state == State.PROCESSING; }
    public boolean isCompleted() { return state == State.COMPLETED; }
    
    // Getters
    public ImageData getImageData() { return imageData; }
    public State getState() { return state; }
    public InversionResult getResult() { return result; }
    
    // Equality: by identity
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Image)) return false;
        Image image = (Image) o;
        return id.equals(image.id);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}

enum State {
    PENDING, VALIDATION, QUEUED, PROCESSING, COMPLETED, FAILED, ARCHIVED
}
```

---

## 2. Value Object Pattern

### Definition
Immutable object defined by its attributes (no identity). Two VOs with same attributes are equal.

### Image Inverter: ImageData Value Object

**Location:** `backend/domain/value_objects/ImageData.java`

```java
public final class ImageData {
    private final byte[] pixels;
    private final int width;
    private final int height;
    private final ImageFormat format;
    private final ColorSpace colorSpace;
    
    public ImageData(byte[] pixels, int width, int height, 
                     ImageFormat format, ColorSpace colorSpace) {
        this.pixels = Objects.requireNonNull(pixels).clone();
        this.width = validateWidth(width);
        this.height = validateHeight(height);
        this.format = Objects.requireNonNull(format);
        this.colorSpace = Objects.requireNonNull(colorSpace);
    }
    
    private int validateWidth(int width) {
        if (width < 1) throw new IllegalArgumentException("Width must be > 0");
        return width;
    }
    
    private int validateHeight(int height) {
        if (height < 1) throw new IllegalArgumentException("Height must be > 0");
        return height;
    }
    
    // Immutable accessors
    public byte[] getPixels() {
        return pixels.clone();
    }
    
    public int getWidth() { return width; }
    public int getHeight() { return height; }
    public ImageFormat getFormat() { return format; }
    public ColorSpace getColorSpace() { return colorSpace; }
    
    // Equality: by value
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof ImageData)) return false;
        ImageData imageData = (ImageData) o;
        return width == imageData.width &&
               height == imageData.height &&
               Arrays.equals(pixels, imageData.pixels) &&
               format == imageData.format &&
               colorSpace == imageData.colorSpace;
    }
    
    @Override
    public int hashCode() {
        int result = Objects.hash(width, height, format, colorSpace);
        result = 31 * result + Arrays.hashCode(pixels);
        return result;
    }
    
    @Override
    public String toString() {
        return String.format("ImageData{%dx%d, format=%s, colorSpace=%s}", 
                           width, height, format, colorSpace);
    }
}

enum ImageFormat {
    PNG, JPG, JPEG, BMP, GIF
}

enum ColorSpace {
    RGB, RGBA, GRAYSCALE, CMYK
}
```

### Image Inverter: InversionResult Value Object

```java
public final class InversionResult {
    private final byte[] invertedPixels;
    private final long processingTime_ms;
    private final Instant completedAt;
    
    public InversionResult(byte[] invertedPixels, long processingTime_ms) {
        this.invertedPixels = Objects.requireNonNull(invertedPixels).clone();
        this.processingTime_ms = validateTime(processingTime_ms);
        this.completedAt = Instant.now();
    }
    
    private long validateTime(long time) {
        if (time < 0) throw new IllegalArgumentException("Time cannot be negative");
        return time;
    }
    
    public byte[] getInvertedPixels() { return invertedPixels.clone(); }
    public long getProcessingTime_ms() { return processingTime_ms; }
    public Instant getCompletedAt() { return completedAt; }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof InversionResult)) return false;
        InversionResult that = (InversionResult) o;
        return processingTime_ms == that.processingTime_ms &&
               Arrays.equals(invertedPixels, that.invertedPixels) &&
               completedAt.equals(that.completedAt);
    }
    
    @Override
    public int hashCode() {
        int result = Objects.hash(processingTime_ms, completedAt);
        result = 31 * result + Arrays.hashCode(invertedPixels);
        return result;
    }
}
```

---

## 3. Aggregate Pattern

### Definition
Cluster of entities & VOs with an aggregate root. Transaction boundary at aggregate level.

### Image Inverter: ImageProcessing Aggregate

```
Aggregate Root: Image (Entity)
├── Children:
│   ├── ImageData (ValueObject - embedded)
│   ├── ProcessingMetadata (ValueObject - embedded)
│   └── InversionResult (ValueObject - embedded)

Invariants:
  1. Image must have valid ImageData
  2. Image cannot be processed twice
  3. Result only exists after completion
  4. State transitions follow state machine
```

**Location:** `backend/domain/aggregates/ImageProcessingAggregate.java`

```java
public class ImageProcessingAggregate {
    private final Image root;
    
    private ImageProcessingAggregate(Image root) {
        this.root = Objects.requireNonNull(root);
        enforceInvariants();
    }
    
    public static ImageProcessingAggregate create(ImageData imageData) {
        Image image = Image.create(imageData);
        return new ImageProcessingAggregate(image);
    }
    
    // Enforce invariants
    private void enforceInvariants() {
        if (root.getImageData() == null) {
            throw new AggregateInvariantException("Image must have data");
        }
        // Additional invariants...
    }
    
    // Aggregate behavior
    public void startProcessing() {
        if (!root.isPending()) {
            throw new AggregateInvariantException(
                "Cannot process non-pending image"
            );
        }
        root.markProcessing();
    }
    
    public void completeProcessing(InversionResult result) {
        if (!root.isProcessing()) {
            throw new AggregateInvariantException(
                "Cannot complete non-processing image"
            );
        }
        root.markCompleted(result);
        enforceInvariants();
    }
    
    // Access root
    public Image getRoot() { return root; }
    
    // Identity
    public UUID getId() { return root.getId(); }
}
```

---

## 4. Repository Pattern

### Definition
Abstraction for persistence/retrieval of aggregates. Hides implementation details.

**Location:** `backend/domain/repositories/ImageRepository.java`

```java
public interface ImageRepository {
    
    /**
     * Save or update an image aggregate.
     * Enforces aggregate consistency.
     */
    void save(Image image);
    
    /**
     * Retrieve image by ID.
     * Reconstructs aggregate from persistence.
     */
    Image findById(UUID id);
    
    /**
     * Find all images with given state.
     * Common query for processing pipeline.
     */
    List<Image> findByState(State state);
    
    /**
     * Delete image by ID.
     */
    void delete(UUID id);
    
    /**
     * Count total images.
     */
    long count();
}
```

### Repository Adapter (Implementation)

**Location:** `backend/repositories/ImageRepositoryAdapter.java`

```java
@Repository
public class ImageRepositoryAdapter implements ImageRepository {
    
    private final ImageJpaRepository jpaRepository;
    private final ImageMapper mapper;
    
    @Autowired
    public ImageRepositoryAdapter(
        ImageJpaRepository jpaRepository,
        ImageMapper mapper
    ) {
        this.jpaRepository = jpaRepository;
        this.mapper = mapper;
    }
    
    @Override
    public void save(Image image) {
        ImageEntity entity = mapper.toEntity(image);
        jpaRepository.save(entity);
    }
    
    @Override
    public Image findById(UUID id) {
        return jpaRepository.findById(id)
            .map(mapper::toDomain)
            .orElseThrow(() -> new ImageNotFoundException(id));
    }
    
    @Override
    public List<Image> findByState(State state) {
        return jpaRepository.findByState(state.name())
            .stream()
            .map(mapper::toDomain)
            .collect(Collectors.toList());
    }
    
    @Override
    public void delete(UUID id) {
        jpaRepository.deleteById(id);
    }
    
    @Override
    public long count() {
        return jpaRepository.count();
    }
}
```

### Mapper (ACL: Domain ↔ Persistence)

**Location:** `backend/repositories/ImageMapper.java`

```java
@Component
public class ImageMapper {
    
    public Image toDomain(ImageEntity entity) {
        Image image = Image.create(
            new ImageData(
                entity.getPixels(),
                entity.getWidth(),
                entity.getHeight(),
                ImageFormat.valueOf(entity.getFormat()),
                ColorSpace.valueOf(entity.getColorSpace())
            )
        );
        // Restore state
        image.setState(State.valueOf(entity.getState()));
        if (entity.getInvertedPixels() != null) {
            image.setResult(new InversionResult(
                entity.getInvertedPixels(),
                entity.getProcessingTime()
            ));
        }
        return image;
    }
    
    public ImageEntity toEntity(Image image) {
        ImageEntity entity = new ImageEntity();
        entity.setId(image.getId());
        entity.setPixels(image.getImageData().getPixels());
        entity.setWidth(image.getImageData().getWidth());
        entity.setHeight(image.getImageData().getHeight());
        entity.setFormat(image.getImageData().getFormat().name());
        entity.setColorSpace(image.getImageData().getColorSpace().name());
        entity.setState(image.getState().name());
        if (image.getResult() != null) {
            entity.setInvertedPixels(image.getResult().getInvertedPixels());
            entity.setProcessingTime(image.getResult().getProcessingTime_ms());
        }
        entity.setCreatedAt(image.getCreatedAt());
        entity.setModifiedAt(image.getModifiedAt());
        return entity;
    }
}
```

---

## 5. Domain Service Pattern

### Definition
Stateless service for domain logic that doesn't belong to an entity or VO.

**Location:** `backend/domain/services/ImageInversionService.java`

```java
public interface ImageInversionService {
    /**
     * Invert image pixels.
     * @param imageData the image data to invert
     * @return inverted result with metrics
     * @throws InvalidImageException if image is invalid
     */
    InversionResult invert(ImageData imageData);
    
    /**
     * Validate image data.
     * @param imageData to validate
     * @return validation report
     */
    ValidationReport validate(ImageData imageData);
}

@Service
public class ImageInversionServiceImpl implements ImageInversionService {
    
    private final ImageProcessor processor;
    
    @Override
    public InversionResult invert(ImageData imageData) {
        long startTime = System.currentTimeMillis();
        
        byte[] inverted = processor.invertPixels(imageData.getPixels());
        
        long duration = System.currentTimeMillis() - startTime;
        return new InversionResult(inverted, duration);
    }
    
    @Override
    public ValidationReport validate(ImageData imageData) {
        List<ValidationError> errors = new ArrayList<>();
        
        if (imageData.getWidth() < 1) {
            errors.add(new ValidationError("width", "Must be > 0"));
        }
        if (imageData.getHeight() < 1) {
            errors.add(new ValidationError("height", "Must be > 0"));
        }
        if (imageData.getPixels().length == 0) {
            errors.add(new ValidationError("pixels", "Cannot be empty"));
        }
        
        return new ValidationReport(errors.isEmpty(), errors);
    }
}
```

---

## 6. Factory Pattern

### Definition
Creates complex aggregates while maintaining invariants.

**Location:** `backend/domain/factories/ImageFactory.java`

```java
public class ImageFactory {
    
    public Image createFromBase64(String base64String, ImageFormat format) 
        throws InvalidImageException {
        try {
            byte[] decodedBytes = Base64.getDecoder().decode(base64String);
            BufferedImage bufferedImage = ImageIO.read(
                new ByteArrayInputStream(decodedBytes)
            );
            
            if (bufferedImage == null) {
                throw new InvalidImageException("Cannot decode image");
            }
            
            byte[] pixels = extractPixels(bufferedImage);
            ImageData imageData = new ImageData(
                pixels,
                bufferedImage.getWidth(),
                bufferedImage.getHeight(),
                format,
                detectColorSpace(bufferedImage)
            );
            
            return Image.create(imageData);
        } catch (IOException e) {
            throw new InvalidImageException(e);
        }
    }
    
    private byte[] extractPixels(BufferedImage image) {
        // Complex pixel extraction logic
        // ...
        return pixelBytes;
    }
    
    private ColorSpace detectColorSpace(BufferedImage image) {
        int type = image.getType();
        return switch (type) {
            case BufferedImage.TYPE_INT_RGB -> ColorSpace.RGB;
            case BufferedImage.TYPE_INT_ARGB -> ColorSpace.RGBA;
            case BufferedImage.TYPE_BYTE_GRAY -> ColorSpace.GRAYSCALE;
            default -> ColorSpace.RGB;
        };
    }
}
```

---

## 7. Specification Pattern

### Definition
Encapsulate business rules as composable objects.

**Location:** `backend/domain/specifications/ImageSpecification.java`

```java
public abstract class Specification<T> {
    public abstract boolean isSatisfiedBy(T candidate);
    
    public Specification<T> and(Specification<T> other) {
        return new CompositeSpecification<>(this, other, 
            (a, b) -> a.isSatisfiedBy(b));
    }
    
    public Specification<T> or(Specification<T> other) {
        return new CompositeSpecification<>(this, other,
            (a, b) -> a.isSatisfiedBy(b) || other.isSatisfiedBy(b));
    }
}

public class ValidImageSpecification extends Specification<ImageData> {
    @Override
    public boolean isSatisfiedBy(ImageData imageData) {
        return imageData.getWidth() > 0 &&
               imageData.getHeight() > 0 &&
               imageData.getPixels().length > 0 &&
               isSupportedFormat(imageData.getFormat());
    }
    
    private boolean isSupportedFormat(ImageFormat format) {
        return format != null && 
               (format == ImageFormat.PNG || 
                format == ImageFormat.JPG ||
                format == ImageFormat.JPEG);
    }
}

public class SmallImageSpecification extends Specification<ImageData> {
    private static final int MAX_SIZE = 1024 * 1024; // 1MB
    
    @Override
    public boolean isSatisfiedBy(ImageData imageData) {
        return imageData.getPixels().length <= MAX_SIZE;
    }
}

// Usage:
Specification<ImageData> validAndSmall = 
    new ValidImageSpecification()
        .and(new SmallImageSpecification());

if (validAndSmall.isSatisfiedBy(imageData)) {
    // Process
}
```

---

## Best Practices Checklist

- ✅ **Entities** have identity and lifecycle
- ✅ **ValueObjects** are immutable and compared by value
- ✅ **Aggregates** enforce business invariants
- ✅ **Repositories** hide persistence implementation
- ✅ **Domain Services** contain logic that doesn't fit entities/VOs
- ✅ **Factories** create complex aggregates
- ✅ **Specifications** encapsulate business rules

---

**Last Updated:** December 18, 2025  
**Version:** 1.0  
**Status:** Active Reference
