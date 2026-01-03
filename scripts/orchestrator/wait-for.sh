#!/bin/bash
################################################################################
# Wait For Service - Dependency Management Script
# Waits for a service to be available before proceeding
################################################################################

HOST=$1
PORT=$2
TIMEOUT=${3:-30}

if [ -z "$HOST" ] || [ -z "$PORT" ]; then
    echo "Usage: wait-for.sh <host> <port> [timeout]"
    exit 1
fi

echo "Waiting for $HOST:$PORT to be available (timeout: ${TIMEOUT}s)..."

start_time=$(date +%s)
while true; do
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    
    if (echo > /dev/tcp/$HOST/$PORT) 2>/dev/null; then
        echo "✓ $HOST:$PORT is available!"
        exit 0
    fi
    
    if [ $elapsed -gt $TIMEOUT ]; then
        echo "✗ Timeout waiting for $HOST:$PORT after ${TIMEOUT}s"
        exit 1
    fi
    
    echo -n "."
    sleep 1
done
