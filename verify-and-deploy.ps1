#####################################################################
# yo3 Platform - Verify Build & Deploy Script
# Run this after all docker-compose builds complete
#####################################################################

Write-Host "`n=== STEP 1: Verify All Images Built ===" -ForegroundColor Cyan

$requiredImages = @(
    "yo3-platform-frontend",
    "yo3-platform-data-core",
    "yo3-platform-edge-node",
    "yo3-platform-identity-service", 
    "yo3-platform-middleware",
    "yo3-platform-stream-processing"
)

$builtImages = docker images --format "{{.Repository}}" | Where-Object { $_ -match "yo3-platform" }
$missing = @()

foreach ($image in $requiredImages) {
    if ($builtImages -contains $image) {
        Write-Host "âˆš $image" -ForegroundColor Green
    } else {
        Write-Host "âœ— $image - MISSING" -ForegroundColor Red
        $missing += $image
    }
}

if ($missing.Count -gt 0) {
    Write-Host "`n❌ ERROR: $($missing.Count) image(s) not built yet!" -ForegroundColor Red
    Write-Host "Run: docker-compose build" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n✅ All 6 images built successfully!`n" -ForegroundColor Green

#####################################################################
# STEP 2: Deploy Containers
#####################################################################

Write-Host "=== STEP 2: Deploy All Services ===" -ForegroundColor Cyan

Write-Host "Stopping any existing containers..." -ForegroundColor Yellow
docker-compose down 2>$null

Write-Host "Starting all 9 services (6 apps + 3 databases)..." -ForegroundColor Yellow
docker-compose up -d

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Deployment started!`n" -ForegroundColor Green
} else {
    Write-Host "`n❌ Deployment failed!`n" -ForegroundColor Red
    exit 1
}

#####################################################################
# STEP 3: Wait for Initialization
#####################################################################

Write-Host "=== STEP 3: Waiting for Services (30 seconds) ===" -ForegroundColor Cyan
Start-Sleep -Seconds 30

#####################################################################
# STEP 4: Health Checks
#####################################################################

Write-Host "`n=== STEP 4: Health Check All Services ===`n" -ForegroundColor Cyan

$healthChecks = @(
    @{ Name = "Data-Core Microkernel"; URL = "http://localhost:9090/api/health" },
    @{ Name = "Identity Service"; URL = "http://localhost:8081/api/health" },
    @{ Name = "Stream Processing"; URL = "http://localhost:8082/api/health" },
    @{ Name = "Middleware"; URL = "http://localhost:8091/api/health" }
)

$allHealthy = $true

foreach ($check in $healthChecks) {
    try {
        $response = Invoke-WebRequest -Uri $check.URL -TimeoutSec 5 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "âˆš $($check.Name)" -ForegroundColor Green
        } else {
            Write-Host "âœ— $($check.Name) - Status: $($response.StatusCode)" -ForegroundColor Yellow
            $allHealthy = $false
        }
    } catch {
        Write-Host "âœ— $($check.Name) - $($_.Exception.Message)" -ForegroundColor Red
        $allHealthy = $false
    }
}

#####################################################################
# STEP 5: Container Status
#####################################################################

Write-Host "`n=== STEP 5: Container Status ===`n" -ForegroundColor Cyan
docker-compose ps

#####################################################################
# STEP 6: Access URLs
#####################################################################

Write-Host "`n=== STEP 6: Access URLs ===`n" -ForegroundColor Cyan
Write-Host "Frontend Dashboard:  " -NoNewline; Write-Host "http://localhost:5173" -ForegroundColor Cyan
Write-Host "Zero-Trust Video:    " -NoNewline; Write-Host "http://localhost:5173/showcase/zero-trust" -ForegroundColor Cyan
Write-Host "Data-Core API:       " -NoNewline; Write-Host "http://localhost:9090" -ForegroundColor Cyan
Write-Host "Edge Node API:       " -NoNewline; Write-Host "http://localhost:8080" -ForegroundColor Cyan
Write-Host "Identity Service:    " -NoNewline; Write-Host "http://localhost:8081" -ForegroundColor Cyan
Write-Host "Stream Processing:   " -NoNewline; Write-Host "http://localhost:8082" -ForegroundColor Cyan
Write-Host "Middleware:          " -NoNewline; Write-Host "http://localhost:8091" -ForegroundColor Cyan

#####################################################################
# STEP 7: Export Images
#####################################################################

Write-Host "`n=== STEP 7: Export Container Images ===`n" -ForegroundColor Cyan
Write-Host "To export all images to deployment-package/:" -ForegroundColor Yellow
Write-Host "  .\export-images.ps1`n" -ForegroundColor Green

if ($allHealthy) {
    Write-Host "`n✅ ALL SERVICES HEALTHY!`n" -ForegroundColor Green
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Test Zero-Trust video flow: http://localhost:5173/showcase/zero-trust" -ForegroundColor White
    Write-Host "  2. Run: .\export-images.ps1 to create deployment package" -ForegroundColor White
    Write-Host "  3. Package deployment-package/ directory for production`n" -ForegroundColor White
} else {
    Write-Host "`n⚠️ SOME SERVICES UNHEALTHY`n" -ForegroundColor Yellow
    Write-Host "Check logs: docker-compose logs -f <service-name>`n" -ForegroundColor White
}
