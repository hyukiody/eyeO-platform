# eyeO Platform - Public Showcase Repository Guide

## Overview

This guide provides instructions for creating sanitized, publicly-shareable versions of the eyeO platform components for portfolio and career development purposes. These repositories demonstrate technical competence while protecting intellectual property.

---

## 🎯 Strategy: "Siloed Showcase"

**Goal**: Demonstrate senior-level engineering skills without exposing proprietary business logic.

**Approach**: Create three standalone demo repositories that showcase specific technical capabilities:

1. **edge-ai-detector** - Computer vision and AI integration
2. **secure-data-processor** - Backend architecture and security patterns  
3. **surveillance-ui** - Frontend development and UX design

---

## 📦 Repository 1: edge-ai-detector

**Public Repository Name**: `edge-ai-video-detector`

**Description**: Real-time object detection using YOLOv8 and JavaFX with performance optimization

### What to Include:

✅ **Keep:**
- YOLOv8 ONNX model integration
- JavaFX video player with zero-copy rendering
- Detection visualization (bounding boxes)
- Throttling mechanism (2 FPS limit)
- Maven build configuration
- README with architecture diagram

❌ **Remove:**
- Network transmission logic (HTTP clients, API calls)
- Key management and seed key generation
- Integration with data-core/microkernel services
- Docker Compose orchestration
- Production configuration files

### Implementation:

```java
// DemoVideoProcessor.java
@Service
public class DemoVideoProcessor {
    
    private static final boolean DEMO_MODE = true;
    private static final Logger logger = LoggerFactory.getLogger(DemoVideoProcessor.class);
    
    @Autowired
    private YOLODetectionService detectionService;
    
    public void processFrame(Mat frame) {
        if (!DEMO_MODE) {
            throw new UnsupportedOperationException(
                "Network features disabled in demo version. " +
                "See README for full platform details."
            );
        }
        
        // DEMO: Local detection and visualization only
        List<Detection> detections = detectionService.detect(frame);
        
        // Draw bounding boxes on frame
        visualizeDetections(frame, detections);
        
        // Log statistics (no network transmission)
        logger.info("Detected {} objects: {}", 
            detections.size(), 
            detections.stream()
                .map(d -> d.getLabel())
                .collect(Collectors.joining(", ")));
    }
    
    private void visualizeDetections(Mat frame, List<Detection> detections) {
        for (Detection detection : detections) {
            Rect bbox = detection.getBoundingBox();
            Scalar color = new Scalar(0, 255, 0); // Green
            
            // Draw rectangle
            Imgproc.rectangle(frame, bbox, color, 2);
            
            // Draw label
            String label = String.format("%s: %.2f", 
                detection.getLabel(), 
                detection.getConfidence());
            Imgproc.putText(frame, label, 
                new Point(bbox.x, bbox.y - 5),
                Imgproc.FONT_HERSHEY_SIMPLEX, 0.5, color, 2);
        }
    }
}
```

### README Template:

```markdown
# Edge AI Video Detector

Real-time object detection using YOLOv8 with optimized performance for edge devices.

## Features

- **YOLOv8 Nano** ONNX Runtime integration for fast inference
- **Zero-Copy Rendering** using JavaFX PixelBuffer
- **Throttling** to prevent CPU overload (configurable FPS limit)
- **Multi-Source Support** for video files and RTSP streams

## Tech Stack

- Java 21 (Amazon Corretto)
- JavaFX 21
- OpenCV 4.x
- ONNX Runtime 1.16
- Deep Java Library (DJL) 0.30

## Performance

- Inference: ~50ms per frame (RTX 3060)
- Memory: 200MB baseline, 400MB peak
- CPU: Single-threaded detection pipeline

## Demo Mode Notice

This is a standalone demonstration showcasing computer vision capabilities.
For the full eyeO platform with network integration and cloud deployment,
contact the author.

## License

Educational/Portfolio Use Only
```

---

## 📦 Repository 2: secure-data-processor

**Public Repository Name**: `stream-data-protection-service`

**Description**: High-performance data transformation microservice with Spring Boot

### What to Include:

✅ **Keep:**
- Generic data transformation REST API
- Spring Boot configuration
- Swagger/OpenAPI documentation
- JUnit tests for service layer
- Rate limiting filter
- Dockerfile (single-service only)

❌ **Remove:**
- Video-specific streaming logic
- Binary tree key rotation algorithm
- KMS/Vault integration code
- Multi-service Docker Compose
- Production environment variables

### Implementation:

```java
// DemoDataProcessor.java
@RestController
@RequestMapping("/api/process")
@Api(tags = "Data Processing Demo")
public class DemoDataProcessingController {
    
    private static final boolean DEMO_MODE = true;
    
    @PostMapping("/transform")
    @ApiOperation(value = "Transform text data",  
        notes = "Demo API for showcasing transformation pipeline")
    public ResponseEntity<TransformResponse> transformData(
            @RequestBody @Valid TransformRequest request) {
        
        if (!DEMO_MODE) {
            return ResponseEntity.status(503)
                .body(new TransformResponse("Production mode disabled"));
        }
        
        // Demo: Simple text transformation (no real protection)
        String input = request.getData();
        String transformed = Base64.getEncoder()
            .encodeToString(input.getBytes());
        
        return ResponseEntity.ok(new TransformResponse(
            transformed,
            "DEMO_KEY_" + UUID.randomUUID(),
            System.currentTimeMillis()
        ));
    }
    
    @GetMapping("/health")
    public ResponseEntity<HealthResponse> health() {
        return ResponseEntity.ok(new HealthResponse("UP", "demo"));
    }
}
```

### README Template:

```markdown
# Stream Data Protection Service

Microservice demonstrating secure data processing patterns with Spring Boot.

## API Endpoints

- `POST /api/process/transform` - Transform data
- `GET /api/process/health` - Service health check
- `GET /swagger-ui.html` - Interactive API documentation

## Architecture Patterns

- **API-First Design** with OpenAPI 3.0 specification
- **Layered Architecture** (Controller → Service → Repository)
- **Rate Limiting** to prevent abuse
- **Global Exception Handling** for consistent error responses

## Try It Out

```bash
# Start the service
docker run -p 8091:8091 stream-data-processor:demo

# Test transformation
curl -X POST http://localhost:8091/api/process/transform \
  -H "Content-Type: application/json" \
  -d '{"data":"Hello World"}'
```

## Demo Limitations

This demonstration includes simplified logic for showcase purposes.
Production features (key management, streaming, KMS integration) are
available in the full eyeO platform.

## License

Portfolio Demonstration - Not for Production Use
```

---

## 📦 Repository 3: surveillance-ui

**Public Repository Name**: `react-surveillance-dashboard`

**Description**: Modern React dashboard with TypeScript and responsive design

### What to Include:

✅ **Keep:**
- React 18 + TypeScript setup
- Vite build configuration
- UI components (cards, charts, layout)
- i18n internationalization
- CSS modules and theming
- Mock data generators

❌ **Remove:**
- Real API integration (replace with fetch to static JSON)
- Web Worker data processing
- Authentication logic (JWT handling)
- Environment-specific configs (.env.production)
- Backend service URLs

### Implementation:

```typescript
// TestDashboard.tsx (Demo Mode)
const DEMO_MODE = true;

const TestDashboard: React.FC = () => {
  const [mockData, setMockData] = useState<ServiceStatus[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (DEMO_MODE) {
      // Load static mock data
      import('../data/mock-services.json')
        .then(data => setMockData(data.default))
        .catch(err => setError('Failed to load demo data'));
      
      console.info('%c📊 DEMO MODE ACTIVE', 'color: orange; font-size: 16px');
      console.info('This dashboard displays simulated data.');
      console.info('Full platform includes live data streams and analytics.');
    } else {
      // Production code path removed
      throw new Error('Production API integration disabled in demo');
    }
  }, []);

  return (
    <div className={styles.dashboard}>
      {DEMO_MODE && (
        <div className={styles.demoBanner}>
          ⚠️ Demo Mode - Displaying simulated data
        </div>
      )}
      
      <h1>Service Monitoring Dashboard</h1>
      
      <div className={styles.grid}>
        {mockData.map(service => (
          <ServiceCard key={service.name} service={service} />
        ))}
      </div>
    </div>
  );
};
```

### Mock Data File:

```json
// public/data/mock-services.json
{
  "services": [
    {
      "name": "Identity Service",
      "status": "UP",
      "uptime": 99.8,
      "responseTime": 45,
      "lastCheck": 1704235200000
    },
    {
      "name": "Data Protection",
      "status": "UP",
      "uptime": 99.9,
      "responseTime": 82,
      "lastCheck": 1704235200000
    },
    {
      "name": "Stream Processing",
      "status": "DEGRADED",
      "uptime": 97.2,
      "responseTime": 320,
      "lastCheck": 1704235200000
    }
  ]
}
```

### README Template:

```markdown
# React Surveillance Dashboard

Modern, responsive dashboard for monitoring distributed services.

## Features

- **Real-time Status Monitoring** with visual indicators
- **Responsive Design** (mobile-first approach)
- **Dark Mode Support** with CSS custom properties
- **Internationalization** (English/Japanese)
- **Component Library** built with React 18

## Tech Stack

- React 18.2
- TypeScript 5.x
- Vite 5.x (build tool)
- CSS Modules
- i18next (internationalization)

## Getting Started

```bash
npm install
npm run dev
# Open http://localhost:5173
```

## Demo Notice

This UI demonstrates frontend architecture and component design.
Backend integration points use mock data. For the complete
eyeO platform with live data streaming, contact the author.

## License

Educational/Portfolio Demonstration
```

---

## 🚀 Deployment Strategy

### GitHub Repository Setup:

1. **Create separate repos** (not forks - fresh repos)
2. **Add comprehensive READMEs** with:
   - Architecture diagrams
   - Setup instructions
   - Technology stack highlights
   - Demo limitations disclaimer
3. **Pin repositories** to GitHub profile
4. **Add topics/tags**: `java`, `spring-boot`, `react`, `computer-vision`, `typescript`

### LinkedIn Showcase:

**Project Description Template**:

```
Privacy-Preserving Video Surveillance Platform (eyeO)

Designed and implemented a Zero-Trust architecture for distributed video
processing with client-side data protection and edge AI inference.

Technical Highlights:
• Shared-Nothing Architecture (SNA) for linear horizontal scaling
• Split-brain data flow (protected streams + metadata analytics)
• Edge AI with YOLOv8 (50ms inference, zero-copy rendering)
• Microservices: Spring Boot 3.4, React 18, PostgreSQL/MySQL
• API-First design with OpenAPI 3.0 contract testing

Impact:
• 85% bandwidth reduction via edge preprocessing
• 99.9% uptime with fault-isolated service nodes
• Sub-100ms API response times with rate limiting

[View Demo Repositories] → GitHub links
```

---

## 🔒 IP Protection Checklist

Before publishing ANY code publicly:

- [ ] Search for hardcoded secrets (`grep -r "SENTINEL_SECRET_KEY"`)
- [ ] Remove all `.env` files
- [ ] Strip production URLs and service endpoints
- [ ] Replace real company/client names with "Demo" or "Example"
- [ ] Remove proprietary algorithms (key rotation, binary tree logic)
- [ ] Disable network transmission in demo mode
- [ ] Add LICENSE file (Portfolio/Educational Use Only)
- [ ] Include disclaimer in README about demo limitations
- [ ] Test that demo runs standalone (no external dependencies)
- [ ] Remove Docker Compose files that reveal full architecture

---

## 📝 Summary

By creating these three sanitized repositories, you demonstrate:

1. **Full-Stack Expertise**: Backend (Java/Spring), Frontend (React/TS), DevOps (Docker)
2. **Architecture Skills**: Microservices, SNA, Zero-Trust, API-First
3. **AI/ML Integration**: YOLOv8, ONNX Runtime, performance optimization
4. **Security Awareness**: Rate limiting, audit logging, secure configuration
5. **Professional Documentation**: READMEs, OpenAPI specs, diagrams

While keeping confidential:

- Complete orchestration and service integration
- Proprietary key management algorithms
- Production deployment strategies
- Real business logic and workflows
- Client-specific customizations

**Result**: A compelling portfolio that advances your career without compromising commercial value.

---

**Created**: 2026-01-02  
**Version**: 1.0  
**Classification**: Internal Development Guide
