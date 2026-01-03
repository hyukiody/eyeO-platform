# 🔒 Security & Credentials Management Guide

**Critical:** This document outlines secure credential handling for eyeO Platform v2.0-public.

---

## ⚠️ NEVER COMMIT THESE FILES

The following files **MUST NEVER** be committed to version control:

### Environment Variables
- ❌ `.env` (contains production secrets)
- ❌ `.env.local` (local overrides)
- ❌ `.env.production` (production credentials)
- ❌ `.env.*.local` (any environment-specific secrets)

### Credential Files
- ❌ `*.key` (private keys)
- ❌ `*.pem` (SSL certificates)
- ❌ `*.p12` (certificate bundles)
- ❌ `secrets/*` (any secrets directory)
- ❌ `credentials.json` (API credentials)

### Database Dumps
- ❌ `*.sql` (may contain user data)
- ❌ `backup/*.sql` (database backups)

---

## ✅ Safe Files to Commit

- ✅ `.env.example` (template with placeholders)
- ✅ `.gitignore` (ignore rules)
- ✅ `docker-compose.yml` (uses env vars, not hardcoded)
- ✅ `README.md` (documentation)

---

## 🔐 Secure Setup Process

### 1. Initial Setup

```bash
# Clone repository
git clone https://github.com/yourusername/eyeo-platform-public.git
cd eyeo-platform-public

# Copy template
cp .env.example .env

# NEVER commit .env
git status  # Verify .env is not tracked
```

### 2. Generate Secure Credentials

```bash
# Generate JWT secret (256-bit)
openssl rand -base64 64

# Generate Master Key (256-bit hex)
openssl rand -hex 32

# Generate strong passwords (32 characters)
openssl rand -base64 32 | head -c 32
```

### 3. Update .env File

```bash
# Edit with secure editor (not in shared screen/recording)
code .env  # Or nano .env, vim .env

# Replace ALL "CHANGE_ME" values
# Use generated credentials from step 2
```

### 4. Verify Protection

```bash
# Ensure .env is ignored
git check-ignore .env
# Should output: .env

# Verify not tracked
git status | grep ".env"
# Should NOT appear in tracked files
```

---

## 🚨 If You Accidentally Committed Secrets

### Immediate Actions

1. **Rotate All Credentials Immediately**
   ```bash
   # Change ALL passwords in database
   # Generate new JWT_SECRET_KEY
   # Regenerate EYEO_MASTER_KEY
   # Update production systems
   ```

2. **Remove from Git History**
   ```bash
   # WARNING: Rewrites history, coordinate with team
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch .env" \
     --prune-empty --tag-name-filter cat -- --all
   
   # Force push (if already pushed)
   git push origin --force --all
   git push origin --force --tags
   ```

3. **Alternative: BFG Repo-Cleaner** (Recommended)
   ```bash
   # Install BFG
   # https://rtyley.github.io/bfg-repo-cleaner/
   
   # Remove .env from all commits
   bfg --delete-files .env
   
   # Clean up
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive
   ```

4. **Inform Team**
   - Notify all collaborators
   - Request local repo cleanup
   - Document incident in security log

---

## 🔑 Production Secret Management

### DO NOT use .env in Production

Use a secret management service:

### AWS Secrets Manager
```bash
# Store secret
aws secretsmanager create-secret \
  --name eyeo/prod/jwt-secret \
  --secret-string "your-secret-here"

# Retrieve in application
aws secretsmanager get-secret-value \
  --secret-id eyeo/prod/jwt-secret
```

### Azure Key Vault
```bash
# Store secret
az keyvault secret set \
  --vault-name eyeo-vault \
  --name jwt-secret \
  --value "your-secret-here"

# Retrieve in application
az keyvault secret show \
  --vault-name eyeo-vault \
  --name jwt-secret
```

### HashiCorp Vault
```bash
# Store secret
vault kv put secret/eyeo/jwt-secret value="your-secret"

# Retrieve in application
vault kv get secret/eyeo/jwt-secret
```

---

## 📋 Security Checklist for Public Release

Before publishing v2.0-public:

- [ ] `.env` is in `.gitignore`
- [ ] `.env` is NOT tracked by Git
- [ ] `.env.example` contains only placeholders
- [ ] No hardcoded passwords in source code
- [ ] All secrets use environment variables
- [ ] Production uses KMS/Vault (not `.env`)
- [ ] Security policy documented in `SECURITY.md`
- [ ] Responsible disclosure policy added
- [ ] All team members trained on secure practices

---

## 🛡️ Security Best Practices

### Password Requirements
- Minimum 16 characters
- Mix of uppercase, lowercase, numbers, symbols
- Never reuse across environments
- Rotate every 90 days (production)

### JWT Secrets
- Minimum 256 bits (32 bytes)
- Cryptographically random
- Never log or expose in error messages
- Rotate on any suspected compromise

### Database Credentials
- Separate credentials per service
- Least privilege principle
- No root access from applications
- Use connection pooling with encryption

### API Keys
- Rotate regularly
- Revoke unused keys
- Monitor usage for anomalies
- Never embed in client-side code

---

## 📞 Security Incident Response

If credentials are compromised:

1. **Immediate (0-1 hour)**
   - Rotate all affected credentials
   - Revoke compromised tokens
   - Block suspicious IPs

2. **Short-term (1-24 hours)**
   - Audit access logs
   - Notify affected users
   - Document timeline

3. **Long-term (1-7 days)**
   - Post-mortem analysis
   - Update security procedures
   - Implement additional controls

---

## 📚 References

- [OWASP Secret Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [NIST Password Guidelines](https://pages.nist.gov/800-63-3/)
- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)

---

**Last Updated:** January 3, 2026  
**Version:** 2.0-public  
**Maintained By:** Security Team
