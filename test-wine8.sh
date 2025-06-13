#!/bin/bash

# Test script for Wine 8.0.2 compatibility
# This script tests if using Wine 8.0.2 resolves the Blue Iris service issues

set -e

echo "Blue Iris Wine 8.0.2 Compatibility Test"
echo "======================================="
echo ""

# Check if docker-compose.yaml exists
if [ ! -f "docker-compose.yaml" ]; then
    echo "Error: docker-compose.yaml not found in current directory"
    exit 1
fi

# Create backup
echo "Creating backup of existing volumes..."
BACKUP_DIR="backup-wine8-test-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup existing volumes if they exist
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

# Test both Dockerfile approaches
echo ""
echo "Testing Wine 8.0.2 installation approaches..."

# Test 1: Try the main Dockerfile with wine-8.0.2 package version
echo ""
echo "=== Test 1: Package version approach ==="
echo "Building with main Dockerfile (wine-8.0.2 package)..."
if docker-compose build --no-cache; then
    echo "✓ Build successful with package version approach"
    
    echo "Starting container to test Wine version..."
    docker-compose up -d
    sleep 10
    
    WINE_VERSION=$(docker exec dc-blueiris-app-1 wine --version 2>/dev/null || echo "Failed to get version")
    echo "Wine version: $WINE_VERSION"
    
    if echo "$WINE_VERSION" | grep -q "8.0"; then
        echo "✓ Wine 8.0.x detected - proceeding with full test"
        
        echo "Waiting for Blue Iris initialization..."
        sleep 60
        
        echo "Checking Blue Iris status..."
        ./check-service.sh dc-blueiris-app-1
        
        echo ""
        echo "=== Test 1 Results ==="
        echo "Wine Version: $WINE_VERSION"
        echo "Container Status: $(docker ps --filter name=dc-blueiris-app-1 --format '{{.Status}}')"
        
        # Check if Blue Iris is working
        if docker exec dc-blueiris-app-1 pgrep -f "BlueIris.exe" > /dev/null; then
            echo "✅ SUCCESS: Blue Iris process is running with Wine 8.0.x!"
            echo "🎉 The issue appears to be Wine version related."
            echo ""
            echo "Access Blue Iris at: http://localhost:8080"
            exit 0
        else
            echo "❌ Blue Iris process not running even with Wine 8.0.x"
        fi
    else
        echo "⚠️ Wine 8.0.x not installed, got: $WINE_VERSION"
    fi
    
    docker-compose down
else
    echo "❌ Build failed with package version approach"
fi

# Test 2: Try the alternative Dockerfile
echo ""
echo "=== Test 2: Alternative Dockerfile approach ==="
echo "Building with Dockerfile.wine8..."

# Temporarily modify docker-compose to use Dockerfile.wine8
cp docker-compose.yaml docker-compose.yaml.backup
sed 's/dockerfile: Dockerfile/dockerfile: Dockerfile.wine8/' docker-compose.yaml.backup > docker-compose.yaml

if docker-compose build --no-cache; then
    echo "✓ Build successful with alternative approach"
    
    echo "Starting container to test Wine version..."
    docker-compose up -d
    sleep 10
    
    WINE_VERSION=$(docker exec dc-blueiris-app-1 wine --version 2>/dev/null || echo "Failed to get version")
    echo "Wine version: $WINE_VERSION"
    
    if echo "$WINE_VERSION" | grep -q "8.0"; then
        echo "✓ Wine 8.0.x detected - proceeding with full test"
        
        echo "Waiting for Blue Iris initialization..."
        sleep 60
        
        echo "Checking Blue Iris status..."
        ./check-service.sh dc-blueiris-app-1
        
        echo ""
        echo "=== Test 2 Results ==="
        echo "Wine Version: $WINE_VERSION"
        echo "Container Status: $(docker ps --filter name=dc-blueiris-app-1 --format '{{.Status}}')"
        
        # Check if Blue Iris is working
        if docker exec dc-blueiris-app-1 pgrep -f "BlueIris.exe" > /dev/null; then
            echo "✅ SUCCESS: Blue Iris process is running with Wine 8.0.x!"
            echo "🎉 The issue appears to be Wine version related."
            echo ""
            echo "Access Blue Iris at: http://localhost:8080"
            
            # Restore original docker-compose
            mv docker-compose.yaml.backup docker-compose.yaml
            exit 0
        else
            echo "❌ Blue Iris process not running even with Wine 8.0.x"
        fi
    else
        echo "⚠️ Wine 8.0.x not installed, got: $WINE_VERSION"
    fi
    
    docker-compose down
else
    echo "❌ Build failed with alternative approach"
fi

# Restore original docker-compose
mv docker-compose.yaml.backup docker-compose.yaml

echo ""
echo "=== Test Summary ==="
echo "❌ Both Wine 8.0.2 installation approaches failed"
echo ""
echo "This suggests either:"
echo "1. Wine 8.0.2 packages are not available for Ubuntu Noble"
echo "2. The issue is not solely Wine version related"
echo "3. Additional configuration is needed for Wine 8.0.x compatibility"
echo ""
echo "Next steps:"
echo "1. Check available Wine versions: apt-cache policy winehq-stable"
echo "2. Consider using Ubuntu Jammy base image with Wine 8.0.2"
echo "3. Investigate other compatibility factors"
echo ""
echo "Backup available in: $BACKUP_DIR"