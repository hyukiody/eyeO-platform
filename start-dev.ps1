# ========================================
# yo3 Platform - Quick Start Script
# ========================================
# Starts all containerized services for development testing

param(
    [switch]$Clean = $false,
    [switch]$Logs = $false
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 yo3 Platform - Quick Start" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
try {
    docker info | Out-Null
} catch {
    Write-Host "❌ Error: Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Clean previous deployment if requested
if ($Clean) {
    Write-Host "🧹 Cleaning previous deployment..." -ForegroundColor Yellow
    docker-compose -f docker-compose.dev.yml down -v
    Write-Host "✓ Cleanup complete" -ForegroundColor Green
    Write-Host ""
}

# Copy environment file
if (!(Test-Path ".env")) {
    Write-Host "📝 Creating .env from .env.dev..." -ForegroundColor Yellow
    Copy-Item .env.dev .env
    Write-Host "✓ Environment configured" -ForegroundColor Green
    Write-Host ""
}

# Start services
Write-Host "🚀 Starting services..." -ForegroundColor Yellow
Write-Host ""

docker-compose -f docker-compose.dev.yml up -d

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ All services started successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Service Status:" -ForegroundColor Cyan
    docker-compose -f docker-compose.dev.yml ps
    Write-Host ""
    Write-Host "🌐 Access Points:" -ForegroundColor Cyan
    Write-Host "  Frontend:         http://localhost:5173" -ForegroundColor White
    Write-Host "  Identity Service: http://localhost:8081" -ForegroundColor White
    Write-Host "  Stream Service:   http://localhost:8082" -ForegroundColor White
    Write-Host "  Data Core:        http://localhost:9090" -ForegroundColor White
    Write-Host ""
    Write-Host "🔍 Health Checks:" -ForegroundColor Cyan
    Write-Host "  Identity: http://localhost:8081/actuator/health" -ForegroundColor White
    Write-Host "  Data Core: http://localhost:9090/health" -ForegroundColor White
    Write-Host ""
    
    if ($Logs) {
        Write-Host "📋 Showing logs (Ctrl+C to exit)..." -ForegroundColor Yellow
        Write-Host ""
        docker-compose -f docker-compose.dev.yml logs -f
    } else {
        Write-Host "💡 Tip: Use './start-dev.ps1 -Logs' to view logs" -ForegroundColor Gray
        Write-Host "💡 Tip: Use 'docker-compose -f docker-compose.dev.yml logs -f' to view logs" -ForegroundColor Gray
        Write-Host "💡 Tip: Use './start-dev.ps1 -Clean' to start fresh" -ForegroundColor Gray
    }
} else {
    Write-Host ""
    Write-Host "❌ Error starting services. Check logs with:" -ForegroundColor Red
    Write-Host "   docker-compose -f docker-compose.dev.yml logs" -ForegroundColor Yellow
    exit 1
}
