# ========================================
# YO3 Platform - Stop Script
# ========================================
# Stops all containerized services

param(
    [switch]$RemoveVolumes = $false
)

Write-Host "🛑 Stopping YO3 Platform services..." -ForegroundColor Yellow
Write-Host ""

if ($RemoveVolumes) {
    Write-Host "⚠️  WARNING: This will delete all data volumes!" -ForegroundColor Red
    $confirmation = Read-Host "Are you sure? (yes/no)"
    
    if ($confirmation -eq "yes") {
        docker-compose -f docker-compose.dev.yml down -v
        Write-Host "✓ Services stopped and volumes removed" -ForegroundColor Green
    } else {
        Write-Host "❌ Cancelled" -ForegroundColor Yellow
    }
} else {
    docker-compose -f docker-compose.dev.yml down
    Write-Host "✓ Services stopped (volumes preserved)" -ForegroundColor Green
    Write-Host "💡 Use './stop-dev.ps1 -RemoveVolumes' to delete all data" -ForegroundColor Gray
}

Write-Host ""
