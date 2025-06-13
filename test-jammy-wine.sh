#!/bin/bash

# Quick test for Wine 8.0.2 from Jammy repository on Ubuntu Noble
echo "Testing Wine 8.0.2 installation from Jammy repository on Ubuntu Noble"
echo "===================================================================="
echo ""

# Stop any existing containers
echo "Stopping existing containers..."
docker-compose down 2>/dev/null || echo "No containers to stop"

# Build with the updated Dockerfile
echo ""
echo "Building with Jammy Wine repository..."
if docker-compose build --no-cache; then
    echo "✅ Build successful!"
    
    # Start container and check Wine version
    echo ""
    echo "Starting container to verify Wine version..."
    docker-compose up -d
    
    # Wait for container to be ready
    sleep 15
    
    # Check Wine version
    echo "Checking Wine version..."
    WINE_VERSION=$(docker exec dc-blueiris-app-1 wine --version 2>/dev/null || echo "Failed to get Wine version")
    echo "Wine version: $WINE_VERSION"
    
    if echo "$WINE_VERSION" | grep -q "8.0.2"; then
        echo "🎉 SUCCESS! Wine 8.0.2 installed successfully!"
        echo ""
        echo "Now testing Blue Iris startup..."
        
        # Wait for Blue Iris initialization
        echo "Waiting for Blue Iris initialization (this may take a few minutes)..."
        sleep 90
        
        # Check Blue Iris status
        echo ""
        echo "Checking Blue Iris status..."
        ./check-service.sh dc-blueiris-app-1
        
        # Check if process is running
        if docker exec dc-blueiris-app-1 pgrep -f "BlueIris.exe" > /dev/null; then
            echo ""
            echo "🎉🎉 DOUBLE SUCCESS! 🎉🎉"
            echo "✅ Wine 8.0.2 installed from Jammy repository"
            echo "✅ Blue Iris process is running"
            echo "✅ Ubuntu Noble + Wine 8.0.2 = Working!"
            echo ""
            echo "🌐 Access Blue Iris at: http://localhost:8080"
            echo ""
            echo "The issue was indeed Wine version compatibility!"
            echo "Wine 8.0.2 from Jammy repository works on Ubuntu Noble."
        else
            echo ""
            echo "⚠️ Wine 8.0.2 installed but Blue Iris process not running"
            echo "This suggests additional factors beyond Wine version"
            echo ""
            echo "Check startup logs:"
            echo "docker exec dc-blueiris-app-1 cat /config/blueiris-startup.log"
        fi
        
    elif echo "$WINE_VERSION" | grep -q "8.0"; then
        echo "✅ Wine 8.0.x installed (close enough for testing)"
        echo "Proceeding with Blue Iris test..."
        
        # Continue with Blue Iris test...
        sleep 90
        ./check-service.sh dc-blueiris-app-1
        
        if docker exec dc-blueiris-app-1 pgrep -f "BlueIris.exe" > /dev/null; then
            echo "🎉 Blue Iris working with Wine 8.0.x!"
        else
            echo "❌ Blue Iris not working even with Wine 8.0.x"
        fi
        
    else
        echo "❌ Wine 8.0.2 not installed. Got: $WINE_VERSION"
        echo "This suggests the Jammy repository approach didn't work"
        echo ""
        echo "Available Wine packages:"
        docker exec dc-blueiris-app-1 apt list --installed | grep wine || echo "No Wine packages found"
    fi
    
else
    echo "❌ Build failed"
    echo "This could indicate:"
    echo "1. Dependency conflicts between Ubuntu Noble and Jammy Wine packages"
    echo "2. Missing dependencies for Wine 8.0.2"
    echo "3. Repository configuration issues"
    echo ""
    echo "Check build logs above for specific errors"
fi

echo ""
echo "Test completed. Container is still running for further investigation."
echo "To stop: docker-compose down"