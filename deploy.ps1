# YO3 Platform Deployment Script
# Convergence Container Packaging & Deploy

Write-Host "🚀 YO3 PLATFORM DEPLOYMENT" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

# Phase 1: Verify Build
Write-Host "`n📦 Phase 1: Verifying Container Images..." -ForegroundColor Yellow
docker images | Select-String "yo3-"

# Phase 2: Start Database Services First
Write-Host "`n💾 Phase 2: Starting Database Services..." -ForegroundColor Yellow
docker-compose up -d sentinel-db identity-db stream-db
Start-Sleep -Seconds 15

# Phase 3: Deploy Core Services
Write-Host "`n⚙️  Phase 3: Deploying Core Services..." -ForegroundColor Yellow
docker-compose up -d secure-io-engine identity-service stream-processing
Start-Sleep -Seconds 10

# Phase 4: Deploy Edge & Middleware
Write-Host "`n🌐 Phase 4: Deploying Edge Node & Middleware..." -ForegroundColor Yellow
docker-compose up -d yo3-edge-node image-inverter
Start-Sleep -Seconds 5

# Phase 5: Deploy Gateway
Write-Host "`n🔐 Phase 5: Deploying API Gateway..." -ForegroundColor Yellow
docker-compose up -d api-gateway

# Phase 6: Verify Deployment
Write-Host "`n✅ Phase 6: Verification..." -ForegroundColor Green
docker-compose ps

Write-Host "`n🎯 DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host "=====================" -ForegroundColor Green
Write-Host ""
Write-Host "Services Running:" -ForegroundColor Cyan
Write-Host "  • Data Core:        http://localhost:9090" -ForegroundColor Gray
Write-Host "  • Edge Node:        http://localhost:8080" -ForegroundColor Gray
Write-Host "  • Identity Service: http://localhost:8081" -ForegroundColor Gray
Write-Host "  • Stream Processing http://localhost:8082" -ForegroundColor Gray
Write-Host "  • Middleware:       http://localhost:8091" -ForegroundColor Gray
Write-Host "  • API Gateway:      http://localhost" -ForegroundColor Gray
Write-Host ""
Write-Host "Health Checks:" -ForegroundColor Yellow
Write-Host "  docker-compose ps" -ForegroundColor White
Write-Host "  docker-compose logs -f" -ForegroundColor White
