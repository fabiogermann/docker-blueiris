#!/bin/bash

# Comprehensive compatibility test script
# Tests different approaches to resolve Wine/Blue Iris compatibility issues

set -e

echo "Blue Iris Compatibility Testing Suite"
echo "====================================="
echo ""
echo "This script will test multiple approaches to resolve the installer crash:"
echo "1. Ubuntu Noble + Jammy Wine packages (current approach)"
echo "2. Ubuntu Jammy base + native Wine 8.0.2 (compatibility approach)"
echo ""

# Create backup
BACKUP_DIR="backup-compatibility-test-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup existing volumes if they exist
if docker volume ls | grep -q "dc-blueiris_config"; then
    echo "Backing up existing volumes..."
    docker run --rm -v dc-blueiris_config:/source -v "$(pwd)/$BACKUP_DIR":/backup alpine tar czf /backup/config-backup.tar.gz -C /source . 2>/dev/null || echo "Config backup failed"
    docker run --rm -v dc-blueiris_data:/source -v "$(pwd)/$BACKUP_DIR":/backup alpine tar czf /backup/data-backup.tar.gz -C /source . 2>/dev/null || echo "Data backup failed"
fi

# Stop existing containers
docker-compose down 2>/dev/null || echo "No containers to stop"

# Test 1: Ubuntu Noble + Jammy Wine (current approach)
echo ""
echo "=========================================="
echo "TEST 1: Ubuntu Noble + Jammy Wine 8.0.2"
echo "=========================================="
echo ""

cp docker-compose.yaml docker-compose.yaml.backup

echo "Building with Ubuntu Noble base + Jammy Wine..."
if docker-compose build --no-cache; then
    echo "✅ Build successful"
    
    echo "Starting container..."
    docker-compose up -d
    sleep 15
    
    WINE_VERSION=$(docker exec dc-blueiris-app-1 wine --version 2>/dev/null || echo "Failed")
    echo "Wine version: $WINE_VERSION"
    
    echo "Testing Blue Iris installer..."
    sleep 30
    
    # Check if installer crashes
    INSTALLER_LOGS=$(docker exec dc-blueiris-app-1 cat /config/blueiris-startup.log 2>/dev/null | tail -20)
    
    if echo "$INSTALLER_LOGS" | grep -q "Unhandled exception\|wine: Unhandled"; then
        echo "❌ TEST 1 FAILED: Installer crash detected"
        echo "Installer crash confirmed with Noble + Jammy Wine combination"
        TEST1_RESULT="FAILED - Installer crash"
    elif docker exec dc-blueiris-app-1 test -f "/config/.wine/drive_c/Program Files/Blue Iris 5/BlueIris.exe"; then
        echo "✅ TEST 1 SUCCESS: Blue Iris installed successfully"
        TEST1_RESULT="SUCCESS"
    else
        echo "⚠️ TEST 1 INCONCLUSIVE: No crash but no installation"
        TEST1_RESULT="INCONCLUSIVE"
    fi
    
    docker-compose down
else
    echo "❌ TEST 1 FAILED: Build failed"
    TEST1_RESULT="FAILED - Build error"
fi

# Test 2: Ubuntu Jammy base + native Wine
echo ""
echo "=========================================="
echo "TEST 2: Ubuntu Jammy base + native Wine"
echo "=========================================="
echo ""

# Switch to Jammy base Dockerfile
sed 's/dockerfile: Dockerfile/dockerfile: Dockerfile.jammy-base/' docker-compose.yaml.backup > docker-compose.yaml

echo "Building with Ubuntu Jammy base + native Wine 8.0.2..."
if docker-compose build --no-cache; then
    echo "✅ Build successful"
    
    echo "Starting container..."
    docker-compose up -d
    sleep 15
    
    WINE_VERSION=$(docker exec dc-blueiris-app-1 wine --version 2>/dev/null || echo "Failed")
    echo "Wine version: $WINE_VERSION"
    
    echo "Testing Blue Iris installer..."
    sleep 60  # Give more time for installation
    
    # Check installer results
    INSTALLER_LOGS=$(docker exec dc-blueiris-app-1 cat /config/blueiris-startup.log 2>/dev/null | tail -20)
    
    if echo "$INSTALLER_LOGS" | grep -q "Unhandled exception\|wine: Unhandled"; then
        echo "❌ TEST 2 FAILED: Installer crash still occurs"
        echo "This suggests the issue is not just Noble/Jammy compatibility"
        TEST2_RESULT="FAILED - Installer crash persists"
    elif docker exec dc-blueiris-app-1 test -f "/config/.wine/drive_c/Program Files/Blue Iris 5/BlueIris.exe"; then
        echo "✅ TEST 2 SUCCESS: Blue Iris installed successfully"
        echo "🎉 Ubuntu Jammy base resolves the compatibility issue!"
        TEST2_RESULT="SUCCESS"
        
        # Test if Blue Iris actually runs
        echo "Testing Blue Iris service startup..."
        sleep 30
        if docker exec dc-blueiris-app-1 pgrep -f "BlueIris.exe" > /dev/null; then
            echo "🎉🎉 DOUBLE SUCCESS: Blue Iris is running!"
            TEST2_RESULT="SUCCESS - Fully working"
        else
            echo "⚠️ Blue Iris installed but service not running"
            TEST2_RESULT="SUCCESS - Installation only"
        fi
    else
        echo "⚠️ TEST 2 INCONCLUSIVE: No crash but no installation"
        TEST2_RESULT="INCONCLUSIVE"
    fi
    
    # Keep this container running if successful
    if [[ "$TEST2_RESULT" == "SUCCESS"* ]]; then
        echo ""
        echo "🌐 Container is running - access Blue Iris at: http://localhost:8080"
        echo "To stop: docker-compose down"
    else
        docker-compose down
    fi
else
    echo "❌ TEST 2 FAILED: Build failed"
    TEST2_RESULT="FAILED - Build error"
fi

# Restore original docker-compose
mv docker-compose.yaml.backup docker-compose.yaml

# Summary
echo ""
echo "=========================================="
echo "COMPATIBILITY TEST RESULTS"
echo "=========================================="
echo ""
echo "TEST 1 (Noble + Jammy Wine): $TEST1_RESULT"
echo "TEST 2 (Jammy base + native): $TEST2_RESULT"
echo ""

if [[ "$TEST2_RESULT" == "SUCCESS"* ]]; then
    echo "🎯 RECOMMENDATION: Use Ubuntu Jammy base image"
    echo ""
    echo "The issue appears to be compatibility between:"
    echo "- Ubuntu Noble system libraries"
    echo "- Jammy Wine packages"
    echo "- Blue Iris installer requirements"
    echo ""
    echo "SOLUTION: Use Dockerfile.jammy-base for production"
    echo "This provides:"
    echo "✅ Native Wine 8.0.2 compatibility"
    echo "✅ Proper system library alignment"
    echo "✅ Working Blue Iris installation"
    echo ""
    echo "To implement:"
    echo "1. Update docker-compose.yaml to use Dockerfile.jammy-base"
    echo "2. Rebuild: docker-compose build --no-cache"
    echo "3. Start: docker-compose up -d"
    
elif [[ "$TEST1_RESULT" == "SUCCESS"* ]]; then
    echo "🎯 RECOMMENDATION: Use current Noble approach"
    echo "The Noble + Jammy Wine combination works"
    
else
    echo "🔧 FURTHER INVESTIGATION NEEDED"
    echo ""
    echo "Both approaches failed, suggesting:"
    echo "1. Blue Iris installer compatibility issues with Wine 8.0.2+"
    echo "2. Missing system dependencies"
    echo "3. Wine configuration issues"
    echo ""
    echo "Next steps:"
    echo "1. Try Wine 7.x versions"
    echo "2. Check Blue Iris installer requirements"
    echo "3. Test with different Wine configurations"
fi

echo ""
echo "Backup available in: $BACKUP_DIR"
echo "Detailed logs available in container logs"