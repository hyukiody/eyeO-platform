# EyeO Platform - Deployment Guide

## 🚀 Deployment em Produção

### Pré-requisitos de Infraestrutura

#### Servidor/Cloud Requirements:
- **CPU**: 8 cores mínimo (16 cores recomendado)
- **RAM**: 16GB mínimo (32GB recomendado)
- **Storage**: 500GB SSD (escalável conforme gravações)
- **Rede**: 1Gbps mínimo
- **OS**: Ubuntu 22.04 LTS ou Debian 12

#### Services Externos:
- PostgreSQL 16+ (gerenciado recomendado: AWS RDS, Azure Database)
- S3/Azure Blob Storage para blobs criptografados
- CDN (CloudFront, Azure CDN) para distribuição de vídeos
- Load Balancer (ALB, Azure Load Balancer)
- DNS com SSL (Route53 + ACM, Azure DNS)

---

## 📋 Checklist Pré-Deployment

### Segurança

- [ ] Senhas fortes geradas (min 32 caracteres)
- [ ] Secrets movidos para Secrets Manager
- [ ] Certificados SSL válidos (Let's Encrypt ou comercial)
- [ ] Firewall configurado (apenas portas 80/443 expostas)
- [ ] Fail2ban instalado e configurado
- [ ] SSH key-based authentication
- [ ] Usuários não-root para aplicação
- [ ] Audit logging habilitado

### Database

- [ ] Backup automático configurado (diário mínimo)
- [ ] Replicação configurada (master-slave)
- [ ] Point-in-time recovery habilitado
- [ ] Connection pooling otimizado
- [ ] Índices criados (ver schema SQL)
- [ ] Rotação de logs configurada

### Storage

- [ ] S3/Blob Storage provisionado
- [ ] Lifecycle policies (arquivamento após 90 dias)
- [ ] Versioning habilitado
- [ ] Encryption at rest (S3-SSE, Azure Storage Encryption)
- [ ] Cross-region replication (disaster recovery)
- [ ] Access logs habilitados

### Monitoring

- [ ] CloudWatch/Azure Monitor configurado
- [ ] Alertas configurados (CPU >80%, Memory >85%, Disk >90%)
- [ ] Log aggregation (ELK, Splunk, Datadog)
- [ ] APM configurado (New Relic, Dynatrace)
- [ ] Uptime monitoring (Pingdom, UptimeRobot)
- [ ] Error tracking (Sentry, Rollbar)

---

## 🔧 Deployment Steps

### 1. Preparação do Servidor

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Instalar utilitários
sudo apt install -y git certbot nginx postgresql-client
```

### 2. Configuração de SSL (Let's Encrypt)

```bash
# Parar Nginx temporariamente
sudo systemctl stop nginx

# Obter certificado
sudo certbot certonly --standalone -d eyeo.yourdomain.com

# Certificados estarão em:
# /etc/letsencrypt/live/eyeo.yourdomain.com/fullchain.pem
# /etc/letsencrypt/live/eyeo.yourdomain.com/privkey.pem

# Configurar renovação automática
sudo crontab -e
# Adicionar: 0 3 * * * certbot renew --quiet && docker-compose restart api-gateway
```

### 3. Clone e Configuração

```bash
# Clone repositório
git clone https://github.com/your-org/eyeo-platform.git
cd eyeo-platform

# Configurar variáveis de ambiente
cp .env.example .env
nano .env  # Editar com valores de produção
```

### 4. Configuração de Secrets (AWS Example)

```bash
# Criar secrets no AWS Secrets Manager
aws secretsmanager create-secret \
  --name eyeo/db/password \
  --secret-string "your-strong-db-password"

aws secretsmanager create-secret \
  --name eyeo/master/encryption-key \
  --secret-string "$(openssl rand -base64 32)"

# Atualizar docker-compose.yml para usar secrets
# Ver exemplo em docker-compose.production.yml
```

### 5. Database Setup

```bash
# Se usar RDS, obter endpoint
export DB_HOST="eyeo-db.xxxx.us-east-1.rds.amazonaws.com"

# Executar migrations
docker-compose run --rm middleware \
  java -jar app.jar db migrate

# Verificar schema
docker-compose exec sentinel-db psql -U sentinel_user -d sentinel -c '\dt'
```

### 6. Storage Configuration (S3)

```bash
# Criar bucket
aws s3 mb s3://eyeo-encrypted-videos --region us-east-1

# Configurar lifecycle
aws s3api put-bucket-lifecycle-configuration \
  --bucket eyeo-encrypted-videos \
  --lifecycle-configuration file://s3-lifecycle.json

# s3-lifecycle.json:
{
  "Rules": [{
    "Id": "Archive old videos",
    "Status": "Enabled",
    "Transitions": [{
      "Days": 90,
      "StorageClass": "GLACIER"
    }]
  }]
}

# Configurar CORS
aws s3api put-bucket-cors \
  --bucket eyeo-encrypted-videos \
  --cors-configuration file://s3-cors.json
```

### 7. Deploy

```bash
# Build production images
docker-compose -f docker-compose.yml -f docker-compose.production.yml build

# Start services
docker-compose -f docker-compose.yml -f docker-compose.production.yml up -d

# Verificar status
docker-compose ps

# Verificar logs
docker-compose logs -f
```

### 8. Smoke Tests

```bash
# Health checks
curl https://eyeo.yourdomain.com/health/microkernel
curl https://eyeo.yourdomain.com/health/middleware

# Test upload
curl -X POST https://eyeo.yourdomain.com/api/video/stream/encrypt \
  -H "X-Camera-ID: cam-test" \
  --data-binary "@test.mp4"

# Test event ingestion
curl -X POST https://eyeo.yourdomain.com/api/events/ingest \
  -H "Content-Type: application/json" \
  --data '{"camera_id":"cam-test","detected_class":"person","confidence":0.9,"storage_ref_key":"test_123"}'
```

---

## 🔄 CI/CD Pipeline

### GitHub Actions Example

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Login to ECR
        run: |
          aws ecr get-login-password | docker login --username AWS --password-stdin ${{ secrets.ECR_REGISTRY }}
      
      - name: Build and push images
        run: |
          docker-compose build
          docker-compose push
      
      - name: Deploy to ECS
        run: |
          aws ecs update-service --cluster eyeo-cluster --service eyeo-service --force-new-deployment
```

---

## 📊 Monitoring & Alerting

### CloudWatch Alarms (AWS)

```bash
# CPU > 80%
aws cloudwatch put-metric-alarm \
  --alarm-name eyeo-high-cpu \
  --alarm-description "Alert when CPU exceeds 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2

# Memory > 85%
aws cloudwatch put-metric-alarm \
  --alarm-name eyeo-high-memory \
  --metric-name MemoryUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 85 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2
```

### Log Monitoring (ELK Stack)

```yaml
# docker-compose.monitoring.yml
version: '3.8'
services:
  elasticsearch:
    image: elasticsearch:8.11.0
    environment:
      - discovery.type=single-node
    volumes:
      - es-data:/usr/share/elasticsearch/data
  
  logstash:
    image: logstash:8.11.0
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
  
  kibana:
    image: kibana:8.11.0
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200

volumes:
  es-data:
```

---

## 🔐 Security Hardening

### Nginx Rate Limiting

```nginx
# ops/nginx.conf
http {
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=upload_limit:10m rate=2r/s;
    
    server {
        location /api/video/ {
            limit_req zone=upload_limit burst=5 nodelay;
        }
        
        location /api/events/ {
            limit_req zone=api_limit burst=20 nodelay;
        }
    }
}
```

### Database Security

```sql
-- Criar role read-only para analytics
CREATE ROLE eyeo_readonly;
GRANT CONNECT ON DATABASE sentinel TO eyeo_readonly;
GRANT USAGE ON SCHEMA public TO eyeo_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO eyeo_readonly;

-- Revogar permissões desnecessárias
REVOKE ALL ON SCHEMA public FROM PUBLIC;
```

### Firewall Rules (UFW)

```bash
# Permitir apenas SSH, HTTP, HTTPS
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Log dropped packets
sudo ufw logging on
```

---

## 🔄 Backup Strategy

### Automated Backup Script

```bash
#!/bin/bash
# backup.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups"

# Database backup
docker-compose exec -T sentinel-db pg_dump -U sentinel_user sentinel | gzip > $BACKUP_DIR/db_$DATE.sql.gz

# Upload to S3
aws s3 cp $BACKUP_DIR/db_$DATE.sql.gz s3://eyeo-backups/database/

# Retention: manter últimos 30 dias
find $BACKUP_DIR -name "db_*.sql.gz" -mtime +30 -delete

# Crontab: 0 2 * * * /opt/eyeo/backup.sh
```

---

## 📈 Scaling

### Horizontal Scaling (Docker Swarm)

```bash
# Inicializar swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose.yml -c docker-compose.production.yml eyeo

# Escalar serviços
docker service scale eyeo_crypto-core=3
docker service scale eyeo_middleware=2
docker service scale eyeo_edge-node=5
```

### Load Balancer Configuration (AWS ALB)

```bash
# Criar target group
aws elbv2 create-target-group \
  --name eyeo-targets \
  --protocol HTTPS \
  --port 443 \
  --vpc-id vpc-xxxx \
  --health-check-path /health/microkernel

# Criar load balancer
aws elbv2 create-load-balancer \
  --name eyeo-lb \
  --subnets subnet-xxxx subnet-yyyy \
  --security-groups sg-xxxx
```

---

## 🆘 Disaster Recovery

### Recovery Time Objective (RTO): 2 horas
### Recovery Point Objective (RPO): 1 hora

### DR Procedure

1. **Database Recovery**:
   ```bash
   # Restaurar do snapshot mais recente
   aws rds restore-db-instance-from-db-snapshot \
     --db-instance-identifier eyeo-db-restore \
     --db-snapshot-identifier eyeo-db-snapshot-latest
   ```

2. **Storage Recovery**:
   ```bash
   # Sincronizar de backup region
   aws s3 sync s3://eyeo-backup-dr/ s3://eyeo-encrypted-videos/
   ```

3. **Service Recovery**:
   ```bash
   # Deploy em região secundária
   docker-compose -f docker-compose.production-dr.yml up -d
   ```

---

## 📝 Runbook

### Incident Response

1. **High CPU/Memory**:
   - Check logs: `docker-compose logs --tail=100`
   - Scale up: `docker service scale eyeo_crypto-core=5`
   - Investigate slow queries

2. **Database Connection Issues**:
   - Check pool: `SELECT * FROM pg_stat_activity;`
   - Restart connections: `docker-compose restart middleware`
   - Check network: `docker-compose exec middleware ping sentinel-db`

3. **Storage Full**:
   - Check usage: `df -h`
   - Archive old videos to Glacier
   - Increase volume size

---

**Deploy com confiança! 🚀**
