#!/usr/bin/env pwsh
<#
.SYNOPSIS
    YO3 Platform - Production Deployment Script (Windows)
.DESCRIPTION
    Deploys the YO3 Zero-Trust Surveillance Platform with health checks
.PARAMETER LoadImages
    Load Docker images from tar files
.PARAMETER Deploy
    Deploy containers with docker-compose
.PARAMETER Verify
    Run health checks on deployed services
#>

param(
    [switch]$LoadImages,
    [switch]$Deploy,
    [switch]$Verify,
    [switch]$All
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Colors
function Write-Success { param($msg) Write-Host "✅ $msg" -ForegroundColor Green }
function Write-Error-Custom { param($msg) Write-Host "❌ $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host "ℹ️  $msg" -ForegroundColor Cyan }
function Write-Warning-Custom { param($msg) Write-Host "⚠️  $msg" -ForegroundColor Yellow }

Write-Host @"
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║   YO3 Platform - Zero-Trust Surveillance System                ║
║   Deployment Script v1.0.0                                     ║
║   CaCTUs Architecture                                          ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Set default to all if no switches
if (-not ($LoadImages -or $Deploy -or $Verify)) {
    $All = $true
}

if ($All) {
    $LoadImages = $true
    $Deploy = $true
    $Verify = $true
}

# Prerequisites Check
Write-Info "Checking prerequisites..."

# Check Docker
try {
    $dockerVersion = docker version --format '{{.Server.Version}}' 2>$null
    if ($dockerVersion) {
        Write-Success "Docker Engine $dockerVersion detected"
    } else {
        throw "Docker not responding"
    }
} catch {
    Write-Error-Custom "Docker is not installed or not running"
    Write-Info "Please install Docker Desktop and ensure it's running"
    exit 1
}

# Check docker-compose
try {
    $composeVersion = docker-compose version --short 2>$null
    if ($composeVersion) {
        Write-Success "Docker Compose $composeVersion detected"
    } else {
        throw "Docker Compose not found"
    }
} catch {
    Write-Error-Custom "Docker Compose is not installed"
    exit 1
}

# Check .env file
if (-not (Test-Path ".env")) {
    Write-Warning-Custom ".env file not found"
    if (Test-Path ".env.example") {
        Write-Info "Copying .env.example to .env..."
        Copy-Item ".env.example" ".env"
        Write-Warning-Custom "CRITICAL: Edit .env with production secrets before deploying!"
        Write-Host ""
        Write-Host "Required changes:" -ForegroundColor Yellow
        Write-Host "  - JWT_SECRET (min 32 chars)" -ForegroundColor Yellow
        Write-Host "  - DB_PASSWORD" -ForegroundColor Yellow
        Write-Host "  - YO3_MASTER_KEY" -ForegroundColor Yellow
        Write-Host "  - DEVICE_TOKEN" -ForegroundColor Yellow
        Write-Host ""
        $continue = Read-Host "Continue deployment? (y/N)"
        if ($continue -ne 'y' -and $continue -ne 'Y') {
            Write-Info "Deployment cancelled"
            exit 0
        }
    } else {
        Write-Error-Custom ".env.example not found. Cannot proceed."
        exit 1
    }
} else {
    Write-Success ".env file found"
}

# Load Docker Images
if ($LoadImages) {
    Write-Info "Loading Docker images..."
    $imageDir = ".\images"
    
    if (Test-Path $imageDir) {
        $tarFiles = Get-ChildItem "$imageDir\*.tar"
        if ($tarFiles.Count -eq 0) {
            Write-Warning-Custom "No .tar files found in $imageDir"
        } else {
            foreach ($tar in $tarFiles) {
                Write-Info "Loading $($tar.Name)..."
                docker load -i $tar.FullName
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Loaded $($tar.Name)"
                } else {
                    Write-Error-Custom "Failed to load $($tar.Name)"
                }
            }
        }
    } else {
        Write-Warning-Custom "Images directory not found. Skipping image load."
        Write-Info "If images are not in registry, build them with: docker-compose build"
    }
}

# Deploy Containers
if ($Deploy) {
    Write-Info "Deploying YO3 Platform containers..."
    
    # Stop existing containers
    Write-Info "Stopping existing containers..."
    docker-compose down 2>$null
    
    # Pull/build images if needed
    Write-Info "Ensuring images are ready..."
    docker-compose pull 2>$null
    
    # Start services
    Write-Info "Starting services..."
    docker-compose up -d
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Containers deployed successfully"
    } else {
        Write-Error-Custom "Container deployment failed"
        Write-Info "Check logs with: docker-compose logs"
        exit 1
    }
    
    Write-Info "Waiting for services to initialize (30s)..."
    Start-Sleep -Seconds 30
}

# Verify Deployment
if ($Verify) {
    Write-Info "Verifying deployment health..."
    
    # Check container status
    Write-Info "Container status:"
    docker-compose ps
    
    # Health check endpoints
    $healthChecks = @(
        @{Name="Identity Service"; URL="http://localhost:8081/api/health"},
        @{Name="Data-Core (Microkernel)"; URL="http://localhost:9090/api/health"},
        @{Name="Stream Processing"; URL="http://localhost:8082/api/health"},
        @{Name="Middleware"; URL="http://localhost:8091/api/health"}
    )
    
    Write-Host ""
    Write-Info "Health check results:"
    $allHealthy = $true
    
    foreach ($check in $healthChecks) {
        try {
            $response = Invoke-WebRequest -Uri $check.URL -TimeoutSec 5 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Success "$($check.Name): Healthy"
            } else {
                Write-Warning-Custom "$($check.Name): Status $($response.StatusCode)"
                $allHealthy = $false
            }
        } catch {
            Write-Error-Custom "$($check.Name): Unreachable"
            $allHealthy = $false
        }
    }
    
    Write-Host ""
    if ($allHealthy) {
        Write-Success "All services are healthy!"
        Write-Host ""
        Write-Host "Access Points:" -ForegroundColor Cyan
        Write-Host "  Frontend:      http://localhost:5173" -ForegroundColor White
        Write-Host "  Identity API:  http://localhost:8081" -ForegroundColor White
        Write-Host "  Data-Core API: http://localhost:9090" -ForegroundColor White
        Write-Host "  Stream API:    http://localhost:8082" -ForegroundColor White
        Write-Host "  Middleware:    http://localhost:8091" -ForegroundColor White
        Write-Host ""
        Write-Host "Useful Commands:" -ForegroundColor Cyan
        Write-Host "  View logs:     docker-compose logs -f" -ForegroundColor White
        Write-Host "  Stop services: docker-compose down" -ForegroundColor White
        Write-Host "  Restart:       docker-compose restart" -ForegroundColor White
    } else {
        Write-Warning-Custom "Some services are not healthy. Check logs:"
        Write-Host "  docker-compose logs -f" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Success "Deployment script completed"
