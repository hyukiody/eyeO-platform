# Image Inverter - Architecture & Documentation Index

## 📖 Quick Navigation

### 🏗 Core Architecture Documents

1. **[SETUP_GUIDE.md](./SETUP_GUIDE.md)** ⭐ **START HERE**
   - Complete project overview
   - Layer-by-layer breakdown
   - Data flow walkthrough
   - Feature implementation checklist

2. **[LOGIC_NOTATION.md](./architecture/LOGIC_NOTATION.md)**
   - Formal mathematical definitions
   - DDD building blocks notation
   - Hexagonal architecture layers
   - Type systems & generics
   - State machines & transitions

3. **[ARCHITECTURE_REFERENCE.md](./architecture/ARCHITECTURE_REFERENCE.md)**
   - Quick reference mapping
   - Package structure
   - Repository patterns
   - Event flows
   - Dependency injection map

---

### 🎯 Pattern Implementation Guides

4. **[DDD_PATTERNS.md](./patterns/DDD_PATTERNS.md)**
   - Entity pattern with examples
   - Value Object pattern
   - Aggregate pattern
   - Repository pattern
   - Domain Service pattern
   - Factory pattern
   - Specification pattern

5. **[EVENT_DRIVEN.md](./patterns/EVENT_DRIVEN.md)**
   - Domain events structure
   - Event publishing
   - Event handlers (sync/async)
   - Event listener configuration
   - Event sourcing (optional)
   - Testing events

---

### 🌐 REST API Documentation

6. **[API_DESIGN.md](./API_DESIGN.md)**
   - REST endpoint specifications
   - DTOs and request/response formats
   - Anti-Corruption Layer (ACL) pattern
   - Error handling & validation
   - Data flow diagrams
   - Testing strategies
   - API versioning

---

## 🎓 Learning Path

### For New Team Members

**Step 1:** Read [SETUP_GUIDE.md](./SETUP_GUIDE.md)
- Get overall project structure
- Understand layer responsibilities
- See complete data flow example

**Step 2:** Review [ARCHITECTURE_REFERENCE.md](./architecture/ARCHITECTURE_REFERENCE.md)
- Map concepts to actual code
- See package organization
- Understand dependency flow

**Step 3:** Study specific patterns
- [DDD_PATTERNS.md](./patterns/DDD_PATTERNS.md) for domain modeling
- [EVENT_DRIVEN.md](./patterns/EVENT_DRIVEN.md) for async communication
- [API_DESIGN.md](./API_DESIGN.md) for REST integration

**Step 4:** Deep dive with [LOGIC_NOTATION.md](./architecture/LOGIC_NOTATION.md)
- Understand mathematical formalism
- Learn formal specifications
- Reference for architecture decisions

---

### For Feature Development

1. **Planning Phase**
   - Use DDD Building Blocks checklist
   - Identify aggregate boundaries
   - Define events

2. **Implementation Phase**
   - Follow layer responsibilities
   - Apply patterns from [DDD_PATTERNS.md](./patterns/DDD_PATTERNS.md)
   - Use [SETUP_GUIDE.md](./SETUP_GUIDE.md) checklist

3. **Testing Phase**
   - Unit test domain layer
   - Integration test application layer
   - API test controllers

4. **Documentation Phase**
   - Update API_DESIGN.md for endpoints
   - Add events to EVENT_DRIVEN.md
   - Update this index if new patterns added

---

### For Architecture Review

- **Code Structure:** Check [ARCHITECTURE_REFERENCE.md](./architecture/ARCHITECTURE_REFERENCE.md)
- **Design Principles:** Review [LOGIC_NOTATION.md](./architecture/LOGIC_NOTATION.md)
- **Pattern Usage:** Verify against [DDD_PATTERNS.md](./patterns/DDD_PATTERNS.md)
- **Event Flow:** Validate with [EVENT_DRIVEN.md](./patterns/EVENT_DRIVEN.md)
- **API Compliance:** Cross-check [API_DESIGN.md](./API_DESIGN.md)

---

## 📊 Document Relationships

```
START_HERE
    ↓
SETUP_GUIDE.md (Overview)
    ├─→ ARCHITECTURE_REFERENCE.md (Quick mapping)
    │      ├─→ DDD_PATTERNS.md (Detailed examples)
    │      ├─→ EVENT_DRIVEN.md (Event handling)
    │      └─→ API_DESIGN.md (REST API)
    │
    └─→ LOGIC_NOTATION.md (Formal definitions)
           ├─→ DDD concepts (mathematically)
           ├─→ Layer definitions (rigorously)
           ├─→ Type systems (formally)
           └─→ State machines (precisely)
```

---

## 🔍 Finding Specific Information

### "How do I add a new entity?"
→ See [DDD_PATTERNS.md](./patterns/DDD_PATTERNS.md) - Entity Pattern section

### "What's the layer structure?"
→ See [ARCHITECTURE_REFERENCE.md](./architecture/ARCHITECTURE_REFERENCE.md) - Clean Architecture section

### "How do events work?"
→ See [EVENT_DRIVEN.md](./patterns/EVENT_DRIVEN.md) - Event Publishing section

### "What's the REST API specification?"
→ See [API_DESIGN.md](./API_DESIGN.md) - Core API Endpoints section

### "How do repositories work?"
→ See [DDD_PATTERNS.md](./patterns/DDD_PATTERNS.md) - Repository Pattern section

### "What are aggregates?"
→ See [DDD_PATTERNS.md](./patterns/DDD_PATTERNS.md) - Aggregate Pattern section

### "How do I test features?"
→ See [SETUP_GUIDE.md](./SETUP_GUIDE.md) - Testing Strategy section

### "What's the data flow?"
→ See [SETUP_GUIDE.md](./SETUP_GUIDE.md) - Data Flow Example & [API_DESIGN.md](./API_DESIGN.md) - Data Flow Diagram

---

## 📋 Architecture Checklist for Features

When implementing a new feature, ensure you have:

**Domain Layer (L₀)**
- [ ] Entity or ValueObject defined
- [ ] Repository interface created
- [ ] Domain Service with business logic
- [ ] DomainEvent(s) for state changes
- [ ] Unit tests for domain logic

**Application Layer (L₁)**
- [ ] Application Service coordinating use case
- [ ] Request/Response DTOs (ACL)
- [ ] Event handlers for async operations
- [ ] Integration tests for service

**Adapter Layer (L₂)**
- [ ] REST Controller with endpoints
- [ ] Input validation with @Valid
- [ ] Error handling via @ExceptionHandler
- [ ] API tests (WebMvcTest)

**Framework Layer (L₃)**
- [ ] Repository implementation (JPA adapter)
- [ ] Entity mapping (Hibernate)
- [ ] Bean configuration if needed
- [ ] Framework-specific code isolated

**Documentation**
- [ ] Add endpoint to [API_DESIGN.md](./API_DESIGN.md)
- [ ] Document events in [EVENT_DRIVEN.md](./patterns/EVENT_DRIVEN.md)
- [ ] Update [SETUP_GUIDE.md](./SETUP_GUIDE.md) if new pattern
- [ ] Add example to [DDD_PATTERNS.md](./patterns/DDD_PATTERNS.md) if reusable

---

## 🎓 Glossary

| Term | Definition | Reference |
|------|-----------|-----------|
| **Entity** | Object with unique identity, lifecycle changes | [DDD_PATTERNS.md](./patterns/DDD_PATTERNS.md#1-entity-pattern) |
| **ValueObject** | Immutable object defined by attributes | [DDD_PATTERNS.md](./patterns/DDD_PATTERNS.md#2-value-object-pattern) |
| **Aggregate** | Cluster of entities/VOs with consistency boundary | [DDD_PATTERNS.md](./patterns/DDD_PATTERNS.md#3-aggregate-pattern) |
| **Repository** | Abstraction for persistence/retrieval | [DDD_PATTERNS.md](./patterns/DDD_PATTERNS.md#4-repository-pattern) |
| **Domain Service** | Stateless operation not belonging to entity/VO | [DDD_PATTERNS.md](./patterns/DDD_PATTERNS.md#6-domain-service-pattern) |
| **DomainEvent** | Significant fact that occurred in domain | [EVENT_DRIVEN.md](./patterns/EVENT_DRIVEN.md#1-domain-events) |
| **ACL** | Anti-Corruption Layer for model translation | [ARCHITECTURE_REFERENCE.md](./architecture/ARCHITECTURE_REFERENCE.md#4-anti-corruption-layer-acl-pattern) |
| **DTO** | Data Transfer Object for API contracts | [API_DESIGN.md](./API_DESIGN.md#3-dtos-anti-corruption-layer) |
| **OHS** | Open Host Service (REST API) | [ARCHITECTURE_REFERENCE.md](./architecture/ARCHITECTURE_REFERENCE.md#7-rest-api-as-open-host-service-ohs) |
| **Layer** | Architectural level (L₀, L₁, L₂, L₃) | [ARCHITECTURE_REFERENCE.md](./architecture/ARCHITECTURE_REFERENCE.md#3-clean-architecture-layer-mapping) |
| **Bounded Context** | Subdomain with explicit boundaries | [LOGIC_NOTATION.md](./architecture/LOGIC_NOTATION.md#2-bounded-context-mapping) |

---

## 🔗 External References

- **Domain-Driven Design:** Evans, E. (2003) "Domain-Driven Design: Tackling Complexity in the Heart of Software"
- **Clean Architecture:** Martin, R. C. (2017) "Clean Architecture: A Craftsman's Guide"
- **Hexagonal Architecture:** Alistair Cockburn - "Ports & Adapters"
- **Event-Driven Architecture:** Microsoft Docs - Event Sourcing & CQRS Patterns

---

## 📞 Documentation Maintenance

### Last Updated
- **Date:** December 18, 2025
- **Version:** 1.0
- **Status:** ✅ Active & Complete

### Contributing to Documentation

When updating documentation:

1. **Keep consistent** with existing terminology
2. **Add examples** from codebase
3. **Update glossary** if introducing new terms
4. **Cross-reference** related documents
5. **Update this index** if adding new documents
6. **Verify links** point to correct files

### Document Update Priority

1. **High:** API_DESIGN.md (affects external contracts)
2. **High:** EVENT_DRIVEN.md (affects system behavior)
3. **Medium:** DDD_PATTERNS.md (affects implementation)
4. **Medium:** SETUP_GUIDE.md (affects onboarding)
5. **Low:** LOGIC_NOTATION.md (reference material)

---

## ✨ Key Principles

1. **Single Responsibility** - Each layer has one reason to change
2. **Dependency Inversion** - Depend on abstractions, not concretions
3. **Bounded Contexts** - Clear domain boundaries
4. **Immutability** - ValueObjects never change
5. **Event-Driven** - Async communication where possible
6. **Type Safety** - Leverage Java's type system
7. **Testability** - Each layer independently testable
8. **Documentation** - Code + docs work together

---

## 🚀 Getting Started

**New to this project?**
1. Start with [SETUP_GUIDE.md](./SETUP_GUIDE.md)
2. Explore your specific area
3. Reference the patterns as needed
4. Keep this index open for navigation

**Adding a feature?**
1. Check [SETUP_GUIDE.md](./SETUP_GUIDE.md) - Feature Checklist
2. Review [DDD_PATTERNS.md](./patterns/DDD_PATTERNS.md) for patterns
3. Follow [ARCHITECTURE_REFERENCE.md](./architecture/ARCHITECTURE_REFERENCE.md) for structure
4. Use [API_DESIGN.md](./API_DESIGN.md) for REST endpoints

**Reviewing code?**
1. Check against [ARCHITECTURE_REFERENCE.md](./architecture/ARCHITECTURE_REFERENCE.md)
2. Verify patterns from [DDD_PATTERNS.md](./patterns/DDD_PATTERNS.md)
3. Validate events with [EVENT_DRIVEN.md](./patterns/EVENT_DRIVEN.md)
4. Cross-check API with [API_DESIGN.md](./API_DESIGN.md)

---

**This documentation is reserved from cloud repository and maintained as the single source of truth for Image Inverter architecture decisions.**

Last Updated: December 18, 2025 | Version 1.0 | Status: ✅ Active
