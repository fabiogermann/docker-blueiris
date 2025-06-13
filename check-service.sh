#!/bin/bash

# Blue Iris Service Status Check Script
# Usage: ./check-service.sh [container_name]

CONTAINER_NAME=${1:-"dc-blueiris-app-1"}

echo "Blue Iris Service Status Check"
echo "=============================="
echo "Container: $CONTAINER_NAME"
echo ""

# Check if container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "❌ Container '$CONTAINER_NAME' is not running"
    echo "Available containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    exit 1
fi

echo "✅ Container is running"
echo ""

# Check Blue Iris processes
echo "Blue Iris Processes:"
echo "-------------------"
if docker exec "$CONTAINER_NAME" pgrep -f "BlueIris.exe" > /dev/null; then
    echo "✅ Blue Iris process is running"
    docker exec "$CONTAINER_NAME" ps aux | grep -i blue | grep -v grep
else
    echo "❌ No Blue Iris process found"
fi
echo ""

# Check Wine services
echo "Wine Services:"
echo "-------------"
docker exec "$CONTAINER_NAME" wine net start 2>/dev/null || echo "❌ Failed to query Wine services"
echo ""

# Check network ports
echo "Network Ports:"
echo "-------------"
if docker exec "$CONTAINER_NAME" netstat -tulpn 2>/dev/null | grep -E ':(8080|81|6900|6901)'; then
    echo "✅ Blue Iris ports are listening"
else
    echo "❌ Blue Iris ports not found"
fi
echo ""

# Check startup log
echo "Recent Startup Log:"
echo "------------------"
if docker exec "$CONTAINER_NAME" test -f /config/blueiris-startup.log; then
    echo "✅ Startup log exists"
    docker exec "$CONTAINER_NAME" tail -10 /config/blueiris-startup.log
else
    echo "❌ No startup log found"
fi
echo ""

# Check Blue Iris installation
echo "Blue Iris Installation:"
echo "----------------------"
if docker exec "$CONTAINER_NAME" test -f "/config/.wine/drive_c/Program Files/Blue Iris 5/BlueIris.exe"; then
    echo "✅ Blue Iris executable found"
else
    echo "❌ Blue Iris executable not found"
fi
echo ""

# Quick service test
echo "Service Test:"
echo "------------"
echo "Attempting to start Blue Iris service..."
SERVICE_OUTPUT=$(docker exec "$CONTAINER_NAME" wine net start blueiris 2>&1)
if echo "$SERVICE_OUTPUT" | grep -q "successfully started\|already running"; then
    echo "✅ Service start command succeeded"
else
    echo "❌ Service start failed:"
    echo "$SERVICE_OUTPUT"
fi
echo ""

# Summary
echo "Summary:"
echo "-------"
PROCESS_RUNNING=$(docker exec "$CONTAINER_NAME" pgrep -f "BlueIris.exe" > /dev/null && echo "YES" || echo "NO")
PORTS_LISTENING=$(docker exec "$CONTAINER_NAME" netstat -tulpn 2>/dev/null | grep -E ':(8080|81)' > /dev/null && echo "YES" || echo "NO")

echo "Blue Iris Process Running: $PROCESS_RUNNING"
echo "Ports Listening: $PORTS_LISTENING"

if [ "$PROCESS_RUNNING" = "YES" ] && [ "$PORTS_LISTENING" = "YES" ]; then
    echo "🎉 Blue Iris appears to be working correctly!"
    echo "   Try accessing: http://localhost:8080"
elif [ "$PROCESS_RUNNING" = "YES" ]; then
    echo "⚠️  Blue Iris is running but ports may not be ready yet"
    echo "   Wait a few minutes and try again"
else
    echo "🔧 Blue Iris needs troubleshooting"
    echo "   Run: ./debug-blueiris.sh $CONTAINER_NAME"
fi