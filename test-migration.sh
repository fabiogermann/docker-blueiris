#!/bin/bash

# Blue Iris Migration Test Script
# This script helps test the Ubuntu Noble migration

set -e

echo "Blue Iris Ubuntu Noble Migration Test"
echo "====================================="
echo ""

# Check if docker-compose.yaml exists
if [ ! -f "docker-compose.yaml" ]; then
    echo "Error: docker-compose.yaml not found in current directory"
    exit 1
fi

# Check if Dockerfile exists
if [ ! -f "Dockerfile" ]; then
    echo "Error: Dockerfile not found in current directory"
    exit 1
fi

echo "✓ Configuration files found"

# Backup existing volumes (if they exist)
echo ""
echo "Creating backup of existing volumes..."
BACKUP_DIR="backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Check if volumes exist and backup
if docker volume ls | grep -q "dc-blueiris_config"; then
    echo "Backing up config volume..."
    docker run --rm -v dc-blueiris_config:/source -v "$(pwd)/$BACKUP_DIR":/backup alpine tar czf /backup/config-backup.tar.gz -C /source . 2>/dev/null || echo "Config backup failed (volume may be empty)"
fi

if docker volume ls | grep -q "dc-blueiris_data"; then
    echo "Backing up data volume..."
    docker run --rm -v dc-blueiris_data:/source -v "$(pwd)/$BACKUP_DIR":/backup alpine tar czf /backup/data-backup.tar.gz -C /source . 2>/dev/null || echo "Data backup failed (volume may be empty)"
fi

echo "✓ Backup completed in $BACKUP_DIR"

# Stop existing containers
echo ""
echo "Stopping existing containers..."
docker-compose down 2>/dev/null || echo "No existing containers to stop"

# Build new image
echo ""
echo "Building new image with Ubuntu Noble..."
docker-compose build --no-cache

echo "✓ Image built successfully"

# Start container
echo ""
echo "Starting container..."
docker-compose up -d

echo "✓ Container started"

# Wait for startup
echo ""
echo "Waiting for Blue Iris to initialize (this may take several minutes)..."
sleep 30

# Check container status
echo ""
echo "Container status:"
docker-compose ps

# Check if ports are accessible
echo ""
echo "Checking port accessibility..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|302\|401"; then
    echo "✓ Port 8080 (VNC) is accessible"
else
    echo "⚠ Port 8080 may not be ready yet"
fi

# Show recent logs
echo ""
echo "Recent container logs:"
echo "====================="
docker-compose logs --tail=20 app

echo ""
echo "Test completed!"
echo ""
echo "Next steps:"
echo "1. Access Blue Iris VNC interface: http://localhost:8080"
echo "2. Check startup logs: docker exec -it dc-blueiris-app-1 cat /config/blueiris-startup.log"
echo "3. Run debug script if issues occur: ./debug-blueiris.sh"
echo "4. Monitor logs: docker-compose logs -f app"
echo ""
echo "If you encounter issues:"
echo "- Check the MIGRATION_GUIDE.md for troubleshooting steps"
echo "- Run the debug script: ./debug-blueiris.sh dc-blueiris-app-1"
echo "- Restore backup if needed from: $BACKUP_DIR"