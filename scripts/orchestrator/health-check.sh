#!/bin/bash
################################################################################
# YO3 Platform Health Check Script
# Verifies all critical services are responding
################################################################################

set -e

# Check if all critical services are responding
echo "🔍 YO3 Platform Health Check"

SERVICES=(
    "http://localhost:8081/actuator/health"  # Identity Service
    "http://localhost:8080/api/v1/health"     # Data Core
    "http://localhost:8082/actuator/health"   # Stream Processing
    "http://localhost:8091/actuator/health"   # Middleware
)

HEALTHY=0
TOTAL=${#SERVICES[@]}

for service in "${SERVICES[@]}"; do
    echo -n "Checking $service ... "
    if curl -sf "$service" > /dev/null 2>&1; then
        echo "✓"
        ((HEALTHY++))
    else
        echo "✗"
    fi
done

echo ""
echo "Services healthy: $HEALTHY/$TOTAL"

if [ $HEALTHY -eq $TOTAL ]; then
    exit 0
else
    exit 1
fi
