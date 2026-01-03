# Docker Hub Publishing Guide

## Overview

This guide explains how to push YO3 Platform Docker images to Docker Hub for public distribution.

## Prerequisites

1. Docker installed and running
2. Docker Hub account (https://hub.docker.com)
3. Docker CLI authenticated with your account

## Quick Push

### 1. Login to Docker Hub

```bash
docker login
# Enter Docker Hub username and password when prompted
```

### 2. Build Local Image (if not already built)

```bash
cd d:\D_ORGANIZED\Development\Projects\yo3-platform\yo3-platform

# Build multi-stage image
docker build -f Dockerfile.orchestrator -t yo3-platform:latest .

# Verify build succeeded
docker images | grep yo3-platform
```

### 3. Tag Image for Docker Hub

Replace `your-docker-username` with your actual Docker Hub username:

```bash
# Tag for Docker Hub
docker tag yo3-platform:latest your-docker-username/yo3-platform:latest
docker tag yo3-platform:latest your-docker-username/yo3-platform:v1.0.0

# Verify tags
docker images | grep yo3-platform
```

### 4. Push to Docker Hub

```bash
# Push latest tag
docker push your-docker-username/yo3-platform:latest

# Push version tag
docker push your-docker-username/yo3-platform:v1.0.0

# Push in background (optional)
docker push your-docker-username/yo3-platform:latest &
docker push your-docker-username/yo3-platform:v1.0.0 &
```

### 5. Verify Push

```bash
# Check Docker Hub (via web interface)
# https://hub.docker.com/r/your-docker-username/yo3-platform

# Or verify via Docker CLI
docker pull your-docker-username/yo3-platform:v1.0.0
docker inspect your-docker-username/yo3-platform:v1.0.0
```

## Automated Pushing via GitHub Actions

### 1. Create GitHub Secrets

In your GitHub repository settings:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Add these secrets:
   - `DOCKER_HUB_USERNAME`: Your Docker Hub username
   - `DOCKER_HUB_TOKEN`: Docker Hub access token (create at https://hub.docker.com/settings/security)
   - `DOCKER_HUB_EMAIL`: Your Docker Hub email

### 2. Create GitHub Actions Workflow

Create `.github/workflows/docker-publish.yml`:

```yaml
name: Docker Publish

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:

jobs:
  docker:
    runs-on: ubuntu-latest
    
    permissions:
      contents: read
      
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_HUB_USERNAME }}
          password: ${{ secrets.DOCKER_HUB_TOKEN }}
      
      - name: Extract version from tag
        id: meta
        run: |
          VERSION=${GITHUB_REF#refs/tags/}
          echo "version=${VERSION}" >> $GITHUB_OUTPUT
          echo "image=${{ secrets.DOCKER_HUB_USERNAME }}/yo3-platform" >> $GITHUB_OUTPUT
      
      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile.orchestrator
          push: true
          tags: |
            ${{ steps.meta.outputs.image }}:${{ steps.meta.outputs.version }}
            ${{ steps.meta.outputs.image }}:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### 3. Push Version Tag to Trigger Workflow

```bash
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions will automatically:
# 1. Build the Dockerfile.orchestrator
# 2. Tag with version (v1.0.0) and latest
# 3. Push to Docker Hub
```

## Multi-Platform Images

To support multiple architectures (x86_64, arm64, etc.):

### 1. Update Dockerfile for Multi-Platform

The `Dockerfile.orchestrator` already supports multi-platform builds using Docker Buildx.

### 2. Build Multi-Platform Image

```bash
# Set up buildx (one-time)
docker buildx create --name multiplatform
docker buildx use multiplatform

# Build for multiple platforms
docker buildx build \
  --file Dockerfile.orchestrator \
  --platform linux/amd64,linux/arm64 \
  --tag your-docker-username/yo3-platform:v1.0.0 \
  --push \
  .
```

### 3. Update GitHub Actions for Multi-Platform

```yaml
- name: Build and push Docker image (Multi-Platform)
  uses: docker/build-push-action@v5
  with:
    context: .
    file: ./Dockerfile.orchestrator
    platforms: linux/amd64,linux/arm64
    push: true
    tags: |
      ${{ steps.meta.outputs.image }}:${{ steps.meta.outputs.version }}
      ${{ steps.meta.outputs.image }}:latest
```

## Publishing Options

### Option 1: Docker Hub (Public Registry)

**Pros:**
- Free public hosting
- Integrated with GitHub
- Official Docker images
- High availability

**Cons:**
- Public visibility
- Rate limiting (6 pulls/6 hours for unauthenticated)
- Limited private repos

**Cost:** Free for unlimited public repos

### Option 2: GitHub Container Registry (GHCR)

**Pros:**
- Integrated with GitHub
- Same token for push/pull
- Linked to repository
- No rate limiting for authenticated users

**Cons:**
- Less discoverable than Docker Hub

**Cost:** Free for unlimited public repos

**Setup:**
```yaml
- name: Login to GitHub Container Registry
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}

- name: Build and push to GHCR
  uses: docker/build-push-action@v5
  with:
    context: .
    file: ./Dockerfile.orchestrator
    push: true
    tags: ghcr.io/${{ github.repository }}:latest
```

### Option 3: Azure Container Registry (ACR)

**Pros:**
- Integrated with Azure
- High performance
- Enterprise support
- Geo-replication

**Cost:** $20/month base + storage/bandwidth

**Setup:**
```bash
az acr login --name myregistry
docker tag yo3-platform:latest myregistry.azurecr.io/yo3-platform:v1.0.0
docker push myregistry.azurecr.io/yo3-platform:v1.0.0
```

### Option 4: AWS Elastic Container Registry (ECR)

**Pros:**
- Integrated with AWS
- VPC endpoint support
- Fine-grained IAM control
- ECR public registry available

**Cost:** $0.07 per GB-month storage

**Setup:**
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com

docker tag yo3-platform:latest 123456789.dkr.ecr.us-east-1.amazonaws.com/yo3-platform:v1.0.0
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/yo3-platform:v1.0.0
```

## Image Size Optimization

Current image size: **~1.37 GB**

### Optimization Strategies

```dockerfile
# 1. Multi-stage builds (already implemented)
FROM eclipse-temurin:21-jdk-alpine AS builder
# ... build steps
FROM eclipse-temurin:21-jdk-alpine
COPY --from=builder /app /app

# 2. Alpine base images
FROM alpine:latest  # ~7MB vs ubuntu:latest ~77MB

# 3. Remove build dependencies
RUN apt-get update && apt-get install -y build-essential \
    && ... build steps ... \
    && apt-get remove -y build-essential && apt-get clean

# 4. Combine RUN commands
RUN apt-get update && \
    apt-get install -y pkg1 pkg2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 5. Use .dockerignore
# Exclude: node_modules, .git, .venv, __pycache__, *.log, target/
```

## Version Management

### Semantic Versioning

Use semantic versioning for releases:

- **v1.0.0** - First stable release
- **v1.1.0** - Minor feature additions (backward compatible)
- **v1.0.1** - Patch releases (bug fixes)
- **v2.0.0** - Major breaking changes

### Docker Tags Strategy

```bash
# Development
docker tag yo3-platform:latest your-username/yo3-platform:dev

# Pre-release
docker tag yo3-platform:latest your-username/yo3-platform:v1.0.0-alpha
docker tag yo3-platform:latest your-username/yo3-platform:v1.0.0-beta
docker tag yo3-platform:latest your-username/yo3-platform:v1.0.0-rc1

# Stable release
docker tag yo3-platform:latest your-username/yo3-platform:v1.0.0
docker tag yo3-platform:latest your-username/yo3-platform:latest
```

## Security Best Practices

### 1. Scan Images for Vulnerabilities

```bash
# Docker Scout (built-in)
docker scout cves yo3-platform:latest

# Trivy (standalone)
trivy image yo3-platform:latest

# Snyk
snyk container test yo3-platform:latest
```

### 2. Use Specific Base Image Versions

```dockerfile
# ❌ Avoid
FROM eclipse-temurin:21-jdk-alpine

# ✅ Use specific version
FROM eclipse-temurin:21.0.1_12-jdk-alpine
```

### 3. Non-Root User

```dockerfile
RUN useradd -m -u 1000 appuser
USER appuser
```

### 4. Read-Only Filesystem (where possible)

```dockerfile
ENTRYPOINT ["dumb-init", "--"]
CMD ["/app/start.sh"]
# Add --read-only flag when running
```

## Rollback Strategy

If there's an issue with a pushed image:

```bash
# 1. Identify the problematic version
docker pull your-username/yo3-platform:v1.0.0

# 2. Revert to previous version
docker tag your-username/yo3-platform:v0.9.9 your-username/yo3-platform:latest
docker push your-username/yo3-platform:latest

# 3. Update documentation with known issues
# 4. Create new release with fixes

# 5. Optional: delete bad image from Docker Hub
# (via Docker Hub web interface or API)
```

## Monitoring Image Usage

```bash
# Check image pull statistics (Docker Hub)
curl -s https://hub.docker.com/v2/repositories/your-username/yo3-platform | jq '.pull_count'

# Monitor in your applications
# Add image digest tracking: your-username/yo3-platform:v1.0.0@sha256:abc123...
```

## Cleanup

### Remove Local Images

```bash
# Remove tag
docker rmi your-username/yo3-platform:v1.0.0

# Remove all yo3-platform images
docker rmi $(docker images 'your-username/yo3-platform' -q)

# Remove dangling images
docker image prune -a
```

### Remove Remote Images (Docker Hub)

1. Go to https://hub.docker.com/r/your-username/yo3-platform
2. Click on "Tags"
3. Click the trash icon next to the version to delete

## Support

For help with Docker Hub:
- [Docker Hub Documentation](https://docs.docker.com/docker-hub/)
- [Docker Hub API](https://docs.docker.com/docker-hub/api/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)

---

See also:
- [DEPLOYMENT.md](DEPLOYMENT.md) - Full deployment guide
- [DOCUMENTATION.md](DOCUMENTATION.md) - Complete documentation
- [README.md](README.md) - Project overview
