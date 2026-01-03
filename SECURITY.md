# Security Policy - EyeO Platform

## 🔒 Reporting Security Vulnerabilities

Se você descobrir uma vulnerabilidade de segurança neste projeto, por favor reporte-a de forma responsável:

1. **NÃO** abra uma issue pública no GitHub
2. Envie um email para: security@eyeo-platform.local
3. Inclua:
   - Descrição detalhada da vulnerabilidade
   - Passos para reproduzir
   - Versão afetada
   - Possível impacto

Responderemos em até 48 horas.

## 🛡️ Segurança por Design

### Princípios Fundamentais

1. **Zero-Trust Architecture**: Nenhum componente confia em outro por padrão
2. **Defense in Depth**: Múltiplas camadas de segurança
3. **Least Privilege**: Cada componente tem apenas as permissões necessárias
4. **Encryption Everywhere**: Dados sempre criptografados em trânsito e em repouso

### Modelo de Ameaças

#### Ameaças Mitigadas:

✅ **Man-in-the-Middle (MITM)**
- Mitigação: TLS/SSL end-to-end, certificados válidos

✅ **Data Breach no Servidor**
- Mitigação: Dados criptografados com chave do cliente (server-blind)

✅ **SQL Injection**
- Mitigação: Prepared statements, JPA/Hibernate

✅ **Cross-Site Scripting (XSS)**
- Mitigação: Content Security Policy, sanitização de inputs

✅ **Cross-Site Request Forgery (CSRF)**
- Mitigação: SameSite cookies, CORS configurado

✅ **Replay Attacks**
- Mitigação: IVs únicos por chunk, timestamps

✅ **Brute Force**
- Mitigação: Rate limiting, account lockout

#### Ameaças Parcialmente Mitigadas:

⚠️ **Physical Access ao Storage**
- Mitigação: Criptografia forte (AES-256-GCM)
- Limitação: Admin com acesso físico pode copiar blobs (mas não descriptografar)

⚠️ **Client Compromise**
- Mitigação: Seed Key nunca enviada ao servidor
- Limitação: Se dispositivo do cliente for comprometido, seed key pode vazar

⚠️ **Insider Threat (DBA)**
- Mitigação: Dados criptografados, audit logging
- Limitação: DBA pode deletar dados (mas não ler conteúdo)

## 🔐 Criptografia

### Algoritmos Utilizados

- **Video Streaming**: AES-256-GCM
  - Key Size: 256 bits
  - IV Size: 96 bits (12 bytes)
  - Tag Size: 128 bits (16 bytes)
  - IV único por chunk (64KB)

- **Key Derivation**: PBKDF2
  - Iterations: 100,000
  - Hash: SHA-256
  - Salt: Aplicação-específico

### Gestão de Chaves

**Desenvolvimento**:
- Master Key gerada em runtime (descartada ao reiniciar)
- Seed Key do usuário em SessionStorage

**Produção (Recomendado)**:
- Master Key armazenada em KMS (AWS KMS, Azure Key Vault, HashiCorp Vault)
- Rotação de chaves a cada 90 dias
- Backup de chaves em HSM

## 🔍 Auditoria e Logging

### Eventos Auditados

Todos os eventos abaixo são registrados:

- ✓ Login/Logout (sem senha)
- ✓ Acesso a vídeos (download de blobs)
- ✓ Upload de vídeos
- ✓ Modificações de configuração
- ✓ Falhas de autenticação
- ✓ Exceções de segurança

### Formato de Log

```json
{
  "timestamp": "2026-01-02T10:30:00Z",
  "event": "VIDEO_ACCESS",
  "user_id": "hash_of_session",
  "storage_key": "cam-01_xxx_yyy",
  "ip_address": "192.168.1.100",
  "user_agent": "Mozilla/5.0...",
  "result": "SUCCESS"
}
```

**Dados NUNCA logados**:
- ❌ Senhas ou Seed Keys
- ❌ Tokens de autenticação completos
- ❌ Conteúdo de vídeos descriptografados
- ❌ Coordenadas GPS exatas

## 🚨 Incident Response Plan

### Severidade de Incidentes

#### Critical (P0)
- Data breach confirmado
- Sistema completamente indisponível
- Acesso não autorizado a dados descriptografados

**SLA**: Resposta em 1 hora, resolução em 4 horas

#### High (P1)
- Vulnerabilidade crítica descoberta
- Degradação severa de performance
- Falha de componente de segurança

**SLA**: Resposta em 4 horas, resolução em 24 horas

#### Medium (P2)
- Vulnerabilidade de severidade média
- Componente secundário indisponível

**SLA**: Resposta em 24 horas, resolução em 7 dias

#### Low (P3)
- Melhorias de segurança
- Vulnerabilidades teóricas

**SLA**: Backlog para próximo sprint

### Procedimento de Resposta

1. **Detecção**: Monitoramento automático ou reporte manual
2. **Contenção**: Isolar componente afetado
3. **Erradicação**: Remover causa raiz
4. **Recuperação**: Restaurar serviço normal
5. **Post-Mortem**: Análise e lessons learned

## 📋 Security Checklist

### Desenvolvimento

- [ ] Code review por pelo menos 2 pessoas
- [ ] Análise estática (SonarQube, Snyk)
- [ ] Testes de segurança automatizados
- [ ] Dependency scan (OWASP Dependency-Check)

### Deployment

- [ ] Senhas geradas com alta entropia (min 32 chars)
- [ ] Secrets em Secrets Manager (não em .env)
- [ ] Certificados SSL válidos (não auto-assinados)
- [ ] Firewall configurado (apenas portas necessárias)
- [ ] Logs centralizados e monitorados
- [ ] Backup testado e validado
- [ ] Disaster recovery plan documentado

### Operação

- [ ] Vulnerability scanning mensal
- [ ] Penetration testing semestral
- [ ] Audit logs revisados semanalmente
- [ ] Access review trimestral
- [ ] Incident response drill anual

## 🔄 Patch Management

- **Critical vulnerabilities**: Patch em 24 horas
- **High vulnerabilities**: Patch em 7 dias
- **Medium vulnerabilities**: Patch em 30 dias
- **Low vulnerabilities**: Next release cycle

## 📞 Contatos de Segurança

- Security Team: security@eyeo-platform.local
- Emergency Hotline: +55 (XX) XXXX-XXXX
- Bug Bounty: https://bugbounty.eyeo-platform.local

## 🏆 Responsible Disclosure

Agradecemos pesquisadores de segurança que reportam vulnerabilidades de forma responsável. Considere participar do nosso programa de Bug Bounty.

---

## 🔐 Credential Management (Public Release)

### Files NEVER to Commit

For the public v2.0 release, the following files **MUST NEVER** be committed:

```
❌ .env (production secrets)
❌ .env.local (local overrides)
❌ .env.production (production credentials)
❌ *.key (private keys)
❌ *.pem (SSL certificates)
❌ secrets/* (credential directories)
```

### Safe Files for Public Repository

```
✅ .env.example (template with placeholders)
✅ .gitignore (properly configured)
✅ docker-compose.yml (uses env vars)
✅ SECURITY_CREDENTIALS.md (security guide)
```

### Verification Commands

```bash
# Verify .env is not tracked
git check-ignore .env
# Output: .env

# Search Git history for sensitive files
git log --all --full-history -- .env
# Output: (empty - no commits)

# Check for secrets in current staging
git status | grep -E "\.env|\.key|\.pem"
# Output: (empty - none staged)
```

### Production Secret Management

**DO NOT use `.env` files in production.** Use managed secret services:

- **AWS:** AWS Secrets Manager / Parameter Store
- **Azure:** Azure Key Vault
- **GCP:** Google Secret Manager
- **Self-hosted:** HashiCorp Vault

See [`SECURITY_CREDENTIALS.md`](SECURITY_CREDENTIALS.md ) for detailed setup instructions.

---

**Última atualização**: 2026-01-03
**Próxima revisão**: 2026-04-03
