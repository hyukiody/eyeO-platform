# EyeO Platform - Architecture Deep Dive

## 📐 Visão Geral da Arquitetura

O EyeO Platform implementa uma arquitetura **Zero-Trust** para vigilância por vídeo, onde nenhum componente intermediário pode acessar o conteúdo dos vídeos.

### Princípios Arquiteturais

1. **Shared-Nothing Architecture**: Cada componente opera independentemente
2. **Blind Storage**: Servidor armazena dados que não consegue ler
3. **Client-Side Decryption**: Apenas o cliente com a Seed Key acessa vídeos
4. **Event-Driven**: Comunicação assíncrona via eventos
5. **Microservices**: Serviços especializados e isolados

---

## 🏛️ Componentes do Sistema

### 1. Edge Node (eyeOSurveillance)
**Porta**: 8090  
**Tecnologia**: Java 17, Spring Boot, VLCj, DJL

**Responsabilidades**:
- Capturar vídeo de câmeras (VLCj/FFmpeg)
- Detecção de objetos em tempo real (YOLOv8)
- Streaming de vídeo bruto ao Microkernel via HTTP chunked
- Disparo de eventos de IA ao Middleware
- **NÃO armazena vídeos localmente**

**Fluxo de Dados**:
```
Camera → VLC Capture → Frame Buffer → ObjectDetection (YOLO)
                              ↓                    ↓
                    Secure Stream Service    Event Ingestion
                              ↓                    ↓
                      Microkernel           Middleware
```

**Classes Principais**:
- `SecureVideoStreamService`: Gerencia streaming HTTP chunked
- `ObjectDetectionService`: Processa frames com IA
- `EventIngestionService`: Envia metadados ao Middleware

---

### 2. Crypto Core (Microkernel)
**Porta**: 8080  
**Tecnologia**: Java 17, Spring Boot, Bouncy Castle

**Responsabilidades**:
- Receber streams de vídeo via HTTP POST
- Criptografar chunks em tempo real (AES-256-GCM)
- Gerar IV único por chunk (anti-padrões)
- Armazenar blobs criptografados em storage
- Servir blobs criptografados para clientes

**Algoritmo de Criptografia**:
```
Para cada chunk de 64KB:
  1. Gera IV aleatório (12 bytes)
  2. Criptografa: AES-256-GCM(chunk, master_key, IV)
  3. Escreve: [IV_SIZE][IV][ENCRYPTED_DATA + TAG]
  4. Retorna storage_key ao finalizar
```

**Storage Layout**:
```
/encrypted-storage/
  cam-01_abc123_1234567890_def456.enc  <- Blob criptografado
  cam-02_xyz789_9876543210_ghi012.enc
  ...
```

**Classes Principais**:
- `SecureStateIOService`: Engine de criptografia
- `StreamController`: Endpoints REST (/stream/encrypt, /storage/{key})

---

### 3. Middleware (Image Inverter - Repurposed)
**Porta**: 8091  
**Tecnologia**: Java 17, Spring Boot, JPA, PostgreSQL

**Responsabilidades**:
- Receber eventos de detecção do Edge Node
- Validar e sanitizar metadados
- Persistir eventos no Sentinel Database
- Fornecer APIs de analytics para Frontend
- **Gatekeeper de dados**: filtra informações sensíveis

**Event Processing Pipeline**:
```
Edge Event → Validation → Sanitization → Encryption (sensitive fields) → PostgreSQL
```

**Sanitização de Dados**:
- Remove coordenadas GPS exatas (mantém apenas região)
- Remove IPs de clientes
- Remove PII (Personally Identifiable Information)

**Classes Principais**:
- `EventIngestionService`: Processa eventos
- `DetectionEventRepository`: Acesso ao banco
- `EventAnalyticsController`: APIs REST

---

### 4. Sentinel Database
**Porta**: 5432 (isolada)  
**Tecnologia**: PostgreSQL 16

**Schema**:
```sql
detection_events (
  id UUID PRIMARY KEY,
  camera_id VARCHAR(100),
  timestamp TIMESTAMPTZ,
  detected_class VARCHAR(50),
  confidence DECIMAL(5,4),
  storage_ref_key VARCHAR(255),  -- Referência ao blob
  encrypted_metadata TEXT,       -- Dados sensíveis criptografados
  created_at TIMESTAMPTZ
)

access_logs (
  id BIGSERIAL PRIMARY KEY,
  event_id UUID REFERENCES detection_events,
  action VARCHAR(50),  -- 'VIEW', 'DOWNLOAD', 'DECRYPT'
  client_ip VARCHAR(45),
  timestamp TIMESTAMPTZ
)

stream_sessions (
  id UUID PRIMARY KEY,
  camera_id VARCHAR(100),
  started_at TIMESTAMPTZ,
  last_chunk_at TIMESTAMPTZ,
  total_bytes BIGINT,
  status VARCHAR(20)  -- 'ACTIVE', 'PAUSED', 'TERMINATED'
)
```

**Security Lockdown**:
```
# pg_hba.conf
host  sentinel  sentinel_user  middleware  md5  # Apenas Middleware
host  all       all            0.0.0.0/0   reject  # Rejeita outros
```

---

### 5. API Gateway (Nginx)
**Portas**: 80 (redir), 443 (SSL)  
**Tecnologia**: Nginx Alpine

**Roteamento**:
```nginx
/api/video/*   → http://secure-io-engine:8080/
/api/events/*  → http://middleware:8091/api/
/api/storage/* → http://secure-io-engine:8080/storage/
/              → http://frontend:5173/
```

**Segurança**:
- TLS 1.2/1.3 obrigatório
- Rate limiting (10 req/s para APIs, 2 req/s para upload)
- Security headers (HSTS, X-Frame-Options, CSP)
- CORS configurado

---

### 6. Frontend (React + Vite)
**Porta**: 5173 (via Gateway)  
**Tecnologia**: React 18, TypeScript, Vite, Chart.js

**Componentes**:
- **Login**: Solicita Seed Key (nunca enviada ao servidor)
- **Dashboard**: Visualiza analytics de eventos
- **VideoPlayer**: Descriptografa e reproduz vídeos

**Client-Side Decryption**:
```typescript
// Web Worker para não bloquear UI
Worker: crypto.worker.ts
  1. Deriva chave AES a partir da Seed Key (PBKDF2)
  2. Baixa blob criptografado do Gateway
  3. Para cada chunk:
     - Lê IV
     - Descriptografa AES-GCM
  4. Concatena chunks em Blob
  5. Cria URL.createObjectURL()
  6. Renderiza em <video>
```

**Segurança do Cliente**:
- Seed Key armazenada em `sessionStorage` (nunca `localStorage`)
- HTTPS obrigatório
- Content Security Policy
- Nenhum dado sensível em cookies

---

## 🔄 Fluxos de Dados Completos

### Fluxo de Gravação de Vídeo (Red Flow)

```
[1] Camera RTSP Stream
     ↓
[2] Edge Node: VLC Capture
     ↓
[3] Edge: SecureVideoStreamService.startSecureStream()
     ↓ HTTP POST chunked
[4] Microkernel: StreamController.encryptVideoStream()
     ↓
[5] Microkernel: SecureStateIO.encryptStream()
     - Para cada 64KB:
       - Gera IV único
       - Criptografa AES-256-GCM
       - Escreve [IV][encrypted_chunk]
     ↓
[6] Storage: Grava blob criptografado
     ↓
[7] Microkernel: Retorna storage_key
     ↓
[8] Edge: Recebe storage_key
     ↓
[9] Edge: EventIngestionService envia metadado ao Middleware
     ↓
[10] Middleware: Persiste evento com storage_key no DB
```

### Fluxo de Detecção de IA (Blue Flow)

```
[1] Edge Node: Captura frame de vídeo
     ↓
[2] Edge: ObjectDetectionService.processFrame()
     ↓
[3] Edge: YOLO inference (DJL)
     - Detecta: class="person", confidence=0.95
     ↓
[4] Edge: if (confidence > threshold && class in targetClasses)
     ↓
[5] Edge: EventIngestionService.sendDetectionEvent()
     - Payload: {camera_id, timestamp, class, confidence, storage_key}
     ↓ HTTP POST JSON
[6] Middleware: EventAnalyticsController.ingestEvent()
     ↓
[7] Middleware: EventIngestionService.ingestEvent()
     - Valida campos obrigatórios
     - Sanitiza metadados sensíveis
     ↓
[8] Middleware: DetectionEventRepository.save()
     ↓
[9] PostgreSQL: INSERT INTO detection_events
```

### Fluxo de Visualização de Vídeo

```
[1] User: Acessa Dashboard via HTTPS
     ↓
[2] Frontend: Login com Seed Key
     - Deriva chave AES localmente
     - Armazena em sessionStorage
     ↓
[3] Frontend: Busca eventos via API
     GET /api/events/range
     ↓
[4] Middleware: Retorna lista de eventos com storage_keys
     ↓
[5] User: Clica "Assistir" em evento
     ↓
[6] Frontend: VideoPlayer component
     ↓
[7] Frontend: Baixa blob criptografado
     GET /api/storage/{storage_key}
     ↓
[8] Gateway: Proxy para Microkernel
     ↓
[9] Microkernel: Serve arquivo .enc criptografado
     ↓
[10] Frontend: Web Worker recebe blob
     ↓
[11] Worker: Descriptografa chunk por chunk
     - Lê IV
     - AES-256-GCM decrypt
     ↓
[12] Worker: Retorna ArrayBuffer descriptografado
     ↓
[13] Frontend: Cria Blob URL
     ↓
[14] Frontend: <video src={blobUrl}> renderiza vídeo
```

---

## 🔐 Modelo de Confiança

### O que cada componente pode fazer:

| Componente | Pode Ler Vídeos? | Pode Modificar? | Pode Deletar? | Trust Level |
|------------|------------------|-----------------|---------------|-------------|
| Edge Node | ❌ (apenas stream) | ✅ Antes de enviar | ❌ | Low |
| Microkernel | ❌ (criptografado) | ❌ | ✅ Admin | Medium |
| Middleware | ❌ (sem acesso) | ❌ | ❌ | Medium |
| Database | ❌ (metadados) | ✅ DBA | ✅ DBA | Low |
| Gateway | ❌ (apenas proxy) | ❌ | ❌ | High |
| Frontend | ✅ Com Seed Key | ❌ | ❌ | User Trust |

### Threat Model:

**Atacante com acesso ao servidor NÃO pode**:
- ❌ Ver conteúdo dos vídeos (criptografados)
- ❌ Alterar vídeos sem detecção (GCM authentication tag)
- ❌ Descriptografar sem Seed Key do cliente

**Atacante com acesso ao banco de dados NÃO pode**:
- ❌ Ver vídeos (apenas storage_keys)
- ❌ Acessar blobs (storage isolado)

**Atacante com acesso físico ao storage NÃO pode**:
- ❌ Descriptografar blobs (precisa de Master Key do KMS + Seed Key do usuário)

**Atacante precisa comprometer**:
- ✅ KMS (para obter Master Key) **E**
- ✅ Cliente do usuário (para obter Seed Key) **E**
- ✅ Storage (para obter blobs)

---

## 📊 Performance & Scalability

### Throughput Esperado

| Métrica | Valor |
|---------|-------|
| Streams simultâneos | 10-50 (single instance) |
| Latência de criptografia | <10ms por chunk 64KB |
| Taxa de upload | ~5-10 MB/s por stream |
| Detecções IA/segundo | ~30 FPS (YOLO) |
| Eventos processados/s | ~1000 (Middleware) |

### Bottlenecks

1. **I/O de Disco**: Storage de blobs grandes
   - Solução: SSD NVMe, S3 multipart upload

2. **CPU (Criptografia)**: AES-GCM é CPU-intensive
   - Solução: AES-NI hardware, scale horizontal

3. **Network**: Upload de vídeo consome banda
   - Solução: Compressão H.264/H.265 antes de criptografar

### Scaling Strategy

**Horizontal Scaling**:
```yaml
# Docker Swarm / Kubernetes
crypto-core: replicas: 3  # Load balanced
middleware: replicas: 2
edge-node: replicas: N    # Um por câmera
```

**Vertical Scaling**:
- Edge Node: GPU para YOLO inference
- Crypto Core: CPU com AES-NI
- Database: Read replicas

---

## 🧪 Testing Strategy

### Unit Tests
- Crypto functions (encrypt/decrypt)
- Event validation
- Sanitization logic

### Integration Tests
- End-to-end streaming
- Event pipeline
- API contracts

### Security Tests
- Penetration testing
- Fuzzing inputs
- Replay attack simulation

### Performance Tests
- Load testing (JMeter, Gatling)
- Stress testing (concurrent streams)
- Soak testing (24h continuous operation)

---

**Documento técnico v1.0 - Janeiro 2026**
