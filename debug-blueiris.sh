#!/bin/bash

# Blue Iris Debug and Monitoring Script
# Usage: ./debug-blueiris.sh [container_name]

CONTAINER_NAME=${1:-"dc-blueiris-app-1"}
LOG_FILE="blueiris-debug-$(date +%Y%m%d-%H%M%S).log"

echo "Blue Iris Debug Script"
echo "======================"
echo "Container: $CONTAINER_NAME"
echo "Log file: $LOG_FILE"
echo ""

# Function to run command in container and log output
run_debug_cmd() {
    local cmd="$1"
    local description="$2"
    
    echo "[$description]" | tee -a "$LOG_FILE"
    echo "Command: $cmd" | tee -a "$LOG_FILE"
    echo "----------------------------------------" | tee -a "$LOG_FILE"
    
    if docker exec "$CONTAINER_NAME" bash -c "$cmd" 2>&1 | tee -a "$LOG_FILE"; then
        echo "✓ Success" | tee -a "$LOG_FILE"
    else
        echo "✗ Failed" | tee -a "$LOG_FILE"
    fi
    
    echo "" | tee -a "$LOG_FILE"
}

# Check if container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "Error: Container '$CONTAINER_NAME' is not running"
    echo "Available containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    exit 1
fi

echo "Starting Blue Iris diagnostics..." | tee "$LOG_FILE"
echo "Timestamp: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# System Information
run_debug_cmd "uname -a" "System Information"
run_debug_cmd "cat /etc/os-release" "OS Version"
run_debug_cmd "free -h" "Memory Usage"
run_debug_cmd "df -h" "Disk Usage"

# Wine Information
run_debug_cmd "wine --version" "Wine Version"
run_debug_cmd "winecfg --version" "Wine Configuration"

# Graphics Information
run_debug_cmd "vulkan-info --summary 2>/dev/null || echo 'Vulkan not available'" "Vulkan Information"
run_debug_cmd "glxinfo | head -20 2>/dev/null || echo 'OpenGL not available'" "OpenGL Information"

# Blue Iris Installation Check
run_debug_cmd "ls -la '/config/.wine/drive_c/Program Files/Blue Iris 5/'" "Blue Iris Installation"
run_debug_cmd "ls -la '/config/.wine/drive_c/Program Files/Blue Iris 5/BlueIris.exe'" "Blue Iris Executable"

# Wine Registry Check
run_debug_cmd "wine reg query 'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\BlueIris'" "Blue Iris Service Registry"

# Process Information
run_debug_cmd "ps aux | grep -i blue" "Blue Iris Processes"
run_debug_cmd "ps aux | grep wine" "Wine Processes"

# Network Information
run_debug_cmd "netstat -tulpn | grep -E ':(8080|81|6900|6901)'" "Network Ports"

# Wine Services
run_debug_cmd "wine net start" "Wine Services Status"

# Blue Iris Logs
run_debug_cmd "cat /config/blueiris-startup.log 2>/dev/null || echo 'Startup log not found'" "Blue Iris Startup Log"

# Wine Debug Information
run_debug_cmd "WINEDEBUG=+service wine net start blueiris 2>&1 || true" "Wine Service Debug"

# File Permissions
run_debug_cmd "ls -la /config/.wine/drive_c/Program\\ Files/Blue\\ Iris\\ 5/BlueIris.exe" "Executable Permissions"

# Wine Configuration
run_debug_cmd "wine reg query 'HKEY_CURRENT_USER\\Software\\Wine\\X11 Driver'" "Wine Graphics Configuration"

echo "Debug information collected in: $LOG_FILE"
echo ""
echo "Common next steps:"
echo "1. Check the startup log for errors"
echo "2. Verify Blue Iris service is registered"
echo "3. Test manual service start: docker exec $CONTAINER_NAME wine net start blueiris"
echo "4. Check graphics capabilities if display issues occur"
echo "5. Review process list for running Blue Iris instances"