#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Export yo3 Platform Docker images for production deployment
.DESCRIPTION
    Saves all yo3 Platform container images to .tar files in deployment-package/images/
#>

$ErrorActionPreference = "Stop"

Write-Host @"
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║   yo3 Platform - Container Export                             ║
║   Packaging for Production Deployment                          ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Create images directory
$imagesDir = ".\deployment-package\images"
if (-not (Test-Path $imagesDir)) {
    New-Item -ItemType Directory -Path $imagesDir -Force | Out-Null
    Write-Host "✅ Created $imagesDir" -ForegroundColor Green
}

# Define images to export (using actual image names from docker images)
$images = @(
    @{Name="yo3-platform-data-core"; Tag="latest"; File="yo3-data-core.tar"},
    @{Name="yo3-platform-yo3-edge-node"; Tag="latest"; File="yo3-edge-node.tar"},
    @{Name="yo3-platform-identity-service"; Tag="latest"; File="yo3-identity.tar"},
    @{Name="yo3-platform-image-inverter"; Tag="latest"; File="yo3-middleware.tar"},
    @{Name="yo3-platform-stream-processing"; Tag="latest"; File="yo3-stream.tar"},
    @{Name="yo3-platform-frontend"; Tag="latest"; File="yo3-frontend.tar"}
)

Write-Host ""
Write-Host "Exporting Docker images..." -ForegroundColor Cyan
Write-Host ""

$total = $images.Count
$current = 0
$successful = 0

foreach ($img in $images) {
    $current++
    $imageName = "$($img.Name):$($img.Tag)"
    $outputFile = Join-Path $imagesDir $img.File
    
    Write-Host "[$current/$total] Exporting $imageName..." -ForegroundColor Yellow
    
    try {
        # Check if image exists
        $imageExists = docker images -q $imageName 2>$null
        if (-not $imageExists) {
            Write-Host "  ⚠️  Image $imageName not found, skipping..." -ForegroundColor Yellow
            continue
        }
        
        # Export image
        docker save -o $outputFile $imageName
        
        if ($LASTEXITCODE -eq 0) {
            # Get file size
            $fileInfo = Get-Item $outputFile
            $sizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
            
            Write-Host "  ✅ Exported to $($img.File) ($sizeMB MB)" -ForegroundColor Green
            $successful++
        } else {
            Write-Host "  ❌ Export failed for $imageName" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ Error: $_" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Copy docker-compose.yml and .env.example
Write-Host "Copying deployment files..." -ForegroundColor Cyan

$deploymentFiles = @(
    @{Source=".\docker-compose.yml"; Dest=".\deployment-package\docker-compose.yml"},
    @{Source=".\.env.example"; Dest=".\deployment-package\.env.example"; Optional=$true}
)

foreach ($file in $deploymentFiles) {
    if (Test-Path $file.Source) {
        Copy-Item $file.Source $file.Dest -Force
        Write-Host "✅ Copied $($file.Source)" -ForegroundColor Green
    } elseif (-not $file.Optional) {
        Write-Host "⚠️  $($file.Source) not found" -ForegroundColor Yellow
    }
}

# Create SHA256 checksums
Write-Host ""
Write-Host "Generating checksums..." -ForegroundColor Cyan
$checksumFile = Join-Path ".\deployment-package" "SHA256SUMS.txt"
$tarFiles = Get-ChildItem "$imagesDir\*.tar" -ErrorAction SilentlyContinue

if ($tarFiles) {
    $checksums = @()
    foreach ($tar in $tarFiles) {
        $hash = Get-FileHash $tar.FullName -Algorithm SHA256
        $checksums += "$($hash.Hash)  images\$($tar.Name)"
    }
    
    $checksums | Out-File -FilePath $checksumFile -Encoding UTF8
    Write-Host "✅ Checksums saved to SHA256SUMS.txt" -ForegroundColor Green
}

# Summary
Write-Host ""
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Export Summary" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Total images:     $total" -ForegroundColor White
Write-Host "Exported:         $successful" -ForegroundColor Green
Write-Host "Skipped:          $($total - $successful)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Output directory: .\deployment-package" -ForegroundColor Cyan
Write-Host ""

if ($successful -gt 0) {
    Write-Host "✅ Export completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Review .\deployment-package\README.md" -ForegroundColor White
    Write-Host "  2. Verify checksums: Get-Content .\deployment-package\SHA256SUMS.txt" -ForegroundColor White
    Write-Host "  3. Copy deployment-package/ to target server" -ForegroundColor White
    Write-Host "  4. On target server, run: .\deploy.ps1" -ForegroundColor White
} else {
    Write-Host "⚠️  No images were exported. Build containers first:" -ForegroundColor Yellow
    Write-Host "  docker-compose build" -ForegroundColor White
}
