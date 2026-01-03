# TeraAPI Project Structure

**Copyright (c) 2026 YiStudIo Software Inc. All rights reserved.**

## Directory Organization

```
teraApi/
├── src/                                    # 📦 Main Source Code
│   ├── identity-service/                   # Identity Provider Service
│   │   ├── src/
│   │   │   ├── main/
│   │   │   │   ├── java/
│   │   │   │   │   └── com/teraapi/identity/
│   │   │   │   │       ├── controller/     # REST Controllers
│   │   │   │   │       ├── service/        # Business Logic
│   │   │   │   │       ├── entity/         # Domain Models
│   │   │   │   │       ├── repository/     # Data Access Layer
│   │   │   │   │       ├── config/         # Spring Configuration
│   │   │   │   │       ├── dto/            # Data Transfer Objects
│   │   │   │   │       └── IdentityServiceApplication.java
│   │   │   │   └── resources/
│   │   │   │       └── application.yml
│   │   │   └── test/
│   │   │       └── java/com/teraapi/identity/
│   │   └── pom.xml
│   │
│   └── stream-processing-service/          # Stream Processing Service
│       ├── src/
│       │   ├── main/
│       │   │   ├── java/
│       │   │   │   └── com/teraapi/stream/
│       │   │   │       ├── StreamProcessingService.java
│       │   │   │       ├── StreamRequestHandler.java
│       │   │   │       ├── JwtValidationUtil.java
│       │   │   │       ├── LicenseValidationService.java
│       │   │   │       └── EncryptionService.java
│       │   │   └── resources/
│       │   └── test/
│       │       └── java/com/teraapi/stream/
│       └── pom.xml
│
├── docker/                                 # 🐳 Docker Configuration
│   ├── Dockerfile.mysql                    # MySQL 8.0 Container
│   ├── Dockerfile.identity                 # IdentityService Container
│   ├── Dockerfile.stream                   # StreamProcessingService Container
│   └── docker-compose.yml                  # Service Orchestration
│
├── docs/                                   # 📚 Documentation
│   ├── README.md                           # Main Project Documentation
│   ├── PROJECT_CHECKPOINT.md               # Implementation Summary
│   ├── DELIVERABLES.md                     # Deliverables Overview
│   └── IMPLEMENTATION_COMPLETE.txt         # Completion Summary
│
├── scripts/                                # 🔧 Utility Scripts
│   ├── init-db.sql                         # Database Initialization
│   ├── setup.sh                            # Linux/Mac Setup Script
│   └── setup.bat                           # Windows Setup Script
│
├── config/                                 # ⚙️ Configuration Files
│   └── [Reserved for additional configs]
│
├── Root Configuration Files
│   ├── pom.xml                             # Parent Maven POM
│   ├── .gitignore                          # Git Ignore Rules
│   ├── .editorconfig                       # Editor Configuration
│   ├── .git/                               # Git Repository
│   └── .github/                            # GitHub Configuration (optional)
│
└── [Additional Project Files]
    └── Typically in root:
        - LICENSE
        - CHANGELOG.md
        - CONTRIBUTING.md
```

---

## Directory Purposes

### `/src` - Source Code
Contains all Java source code organized by module:
- **identity-service/**: Spring Boot application providing JWT authentication
- **stream-processing-service/**: Lightweight Java service for data processing

Each service follows Maven standard directory structure:
```
service/
├── src/main/java/        # Production code
├── src/main/resources/    # Configuration files
├── src/test/java/         # Test code
└── pom.xml                # Service-specific dependencies
```

### `/docker` - Containerization
All Docker-related configuration:
- **Dockerfile.mysql**: MySQL 8.0 database container
- **Dockerfile.identity**: IdentityService Spring Boot container
- **Dockerfile.stream**: StreamProcessingService Java container
- **docker-compose.yml**: Orchestrates all services with networking

### `/docs` - Documentation
Comprehensive project documentation:
- **README.md**: Complete project guide (quick start, API, troubleshooting)
- **PROJECT_CHECKPOINT.md**: Technical implementation details
- **DELIVERABLES.md**: Feature list and deliverables summary
- **IMPLEMENTATION_COMPLETE.txt**: Final completion status

### `/scripts` - Automation & Database
Utility scripts and database initialization:
- **init-db.sql**: MySQL schema and sample data
- **setup.sh**: Linux/Mac development environment setup
- **setup.bat**: Windows development environment setup

### `/config` - Configuration Management
Reserved for environment-specific configurations (not yet populated)

### Root Level
- **pom.xml**: Parent Maven project defining modules and build properties
- **.gitignore**: Git ignore patterns (Maven, IDE, OS files)
- **.editorconfig**: Code style and formatting rules

---

## Service-Specific Structure

### IdentityService (`src/identity-service/`)

```
src/main/java/com/teraapi/identity/
├── controller/
│   └── AuthController.java               # REST endpoints (/api/auth/*)
├── service/
│   ├── AuthenticationService.java        # Auth business logic
│   ├── JwtTokenProvider.java             # Token generation & validation
│   └── MyUserDetailsService.java         # Spring Security integration
├── entity/
│   ├── User.java                         # User domain model
│   └── Role.java                         # Role domain model
├── repository/
│   ├── UserRepository.java               # User data access
│   └── RoleRepository.java               # Role data access
├── config/
│   └── SecurityConfig.java               # Spring Security configuration
├── dto/
│   ├── AuthenticationRequest.java        # Login/Register request
│   └── AuthenticationResponse.java       # Token response
└── IdentityServiceApplication.java       # Spring Boot entry point

src/main/resources/
└── application.yml                       # Service configuration

src/test/
└── java/com/teraapi/identity/           # Unit tests

pom.xml                                   # Maven configuration
```

### StreamProcessingService (`src/stream-processing-service/`)

```
src/main/java/com/teraapi/stream/
├── StreamProcessingService.java          # HTTP server main class
├── StreamRequestHandler.java             # Request routing & handling
├── JwtValidationUtil.java                # JWT signature validation
├── LicenseValidationService.java         # Tier-based access control
└── EncryptionService.java                # AES-256 encryption

src/main/resources/
└── [Configuration if needed]

src/test/
└── java/com/teraapi/stream/             # Unit tests

pom.xml                                   # Maven configuration
```

---

## Build & Deployment Hierarchy

### Development Workflow

```
1. Clone Repository
   └── Local code ready

2. Build (Maven)
   ├── mvn clean install -f pom.xml     # Build all modules
   └── Target JARs created:
       ├── src/identity-service/target/
       └── src/stream-processing-service/target/

3. Package (Docker)
   └── docker/docker-compose.yml
       ├── Builds Docker images
       └── Creates containers

4. Deploy
   └── docker-compose up -d
       ├── MySQL starts
       ├── IdentityService starts
       └── StreamProcessingService starts
```

### File Resolution

```
Configuration Files in Docker:
docker-compose.yml (in docker/)
├── Mounts: ../scripts/init-db.sql
├── Builds: docker/Dockerfile.identity
│   └── COPY src/identity-service/target/...
└── Builds: docker/Dockerfile.stream
    └── COPY src/stream-processing-service/target/...
```

---

## Configuration Management

### Environment Variables

Files containing configuration:
- `src/identity-service/src/main/resources/application.yml` - Service-specific
- `docker/docker-compose.yml` - Docker environment overrides
- `.env` (optional) - Local environment file

### Deployment Paths

**Local Development:**
```
./src/identity-service/
./docker/docker-compose.yml
./scripts/init-db.sql
```

**Docker Compose:**
```
Context: /docker/
├── Searches: ../scripts/init-db.sql
├── Builds: docker/Dockerfile.identity
└── Builds: docker/Dockerfile.stream
```

---

## Package Naming Convention

```
com.teraapi.identity          # IdentityService packages
├── controller
├── service
├── entity
├── repository
├── config
└── dto

com.teraapi.stream            # StreamProcessingService packages
├── [Service classes]
```

---

## File Ownership & Copyright

All Java source files include:
```java
/*
 * TeraAPI - [Service Name]
 * Copyright (c) 2026 YiStudIo Software Inc. All rights reserved.
 * Licensed under proprietary license.
 */
```

---

## Git Repository Structure

```
.git/                         # Git repository (created during init)
  └── Tracks all files except .gitignore patterns

.gitignore                    # Excludes:
  ├── target/                 # Maven build output
  ├── .idea/                  # IDE configurations
  ├── .class files
  ├── .jar files (except source)
  └── Environment files (.env)
```

---

## Quick Navigation

| Need | Location |
|------|----------|
| Main Documentation | `docs/README.md` |
| API Specifications | `docs/README.md#api-endpoints` |
| Database Schema | `scripts/init-db.sql` |
| Service Code | `src/identity-service/` or `src/stream-processing-service/` |
| Docker Setup | `docker/docker-compose.yml` |
| Build Configuration | `pom.xml` (root and service-level) |
| Development Setup | `scripts/setup.sh` or `scripts/setup.bat` |

---

## Best Practices

### Source Code Organization
1. ✅ Code in `/src` organized by service
2. ✅ Clear separation: controller, service, entity, repository, config, dto
3. ✅ Each service is independently deployable
4. ✅ Shared utilities could go in a common module (future)

### Configuration
1. ✅ Application properties in service resources
2. ✅ Docker environment variables in docker-compose.yml
3. ✅ Secrets excluded from git (use .gitignore)
4. ✅ Configuration as code principle

### Documentation
1. ✅ Main README at project root (linked from docs/)
2. ✅ Additional docs in `/docs` folder
3. ✅ Code-level documentation with JavaDoc comments
4. ✅ API documentation in markdown

### Scripts
1. ✅ Database migrations in `/scripts`
2. ✅ Setup automation (setup.sh, setup.bat)
3. ✅ Cross-platform script support

---

## Extending the Structure

### Adding a New Service

1. Create service directory:
   ```bash
   mkdir -p src/new-service/src/main/java/com/teraapi/newservice
   ```

2. Add to root pom.xml modules
3. Create service pom.xml with proper structure
4. Create Dockerfile in `/docker`
5. Update docker-compose.yml

### Adding Documentation

1. Create markdown in `/docs`
2. Link from main README.md
3. Use consistent formatting

### Adding Utilities

1. Database scripts → `/scripts`
2. Deployment scripts → `/scripts`
3. Configuration → `/config` (if needed)

---

## Migration Notes

**Original → Organized Structure:**
```
identity-service/    → src/identity-service/
stream-processing-service/ → src/stream-processing-service/
Dockerfile*          → docker/Dockerfile*
docker-compose.yml   → docker/docker-compose.yml
*.md                 → docs/*.md
init-db.sql         → scripts/init-db.sql
```

All relative paths in configuration files have been updated to reflect this new structure.

---

**© 2026 YiStudIo Software Inc.** | Licensed under proprietary license

*Last Updated: January 2, 2026*
