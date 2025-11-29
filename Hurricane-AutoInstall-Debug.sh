#!/bin/bash
# Hurricane Client - Advanced Auto-Installer (Linux/Mac)
# Single file download - automatically updates from hafenexplorer.github.io
# Advanced error messaging and debugging support

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LAUNCHER_URL="https://hafenexplorer.github.io/launcher.jar"
CONFIG_URL="https://hafenexplorer.github.io/launcher.hl"
INSTALL_DIR="$HOME/.local/share/hurricane"
ERROR_COUNT=0

# Helper functions
print_header() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}   HURRICANE CLIENT AUTO-INSTALLER${NC}"
    echo -e "${CYAN}   https://hafenexplorer.github.io${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}[$1/$2]${NC} $3"
    echo "----------------------------------------"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    ERROR_COUNT=$((ERROR_COUNT + 1))
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Display header
clear
print_header

echo "This installer will:"
echo "  - Check your Java installation"
echo "  - Download the launcher (if needed)"
echo "  - Launch Hurricane client"
echo "  - Automatically update game files"
echo ""
echo "========================================"
echo ""

# ============================================================================
# STEP 1: Check Java Installation
# ============================================================================
print_step 1 5 "Checking Java Installation"

if ! command -v java &> /dev/null; then
    print_error "Java is not installed or not in your PATH"
    echo ""
    echo "SOLUTION:"
    echo "  1. Install Java from: https://adoptium.net/temurin/releases/"
    echo "  2. Choose: JRE (smaller) or JDK"
    echo "  3. Select your platform (Linux x64 or macOS)"
    echo "  4. Install with default settings"
    echo "  5. Restart this installer"
    echo ""
    echo "Quick install commands:"
    echo "  Ubuntu/Debian: sudo apt install openjdk-11-jre"
    echo "  Fedora/RHEL:   sudo dnf install java-11-openjdk"
    echo "  macOS:          brew install openjdk@11"
    echo ""
    read -p "Press Enter to exit..."
    exit 1
fi

print_success "Java found in PATH"
echo ""

# ============================================================================
# STEP 2: Check Java Version
# ============================================================================
print_step 2 5 "Verifying Java Version"

JAVA_VERSION_STRING=$(java -version 2>&1 | head -n 1)
print_info "Detected: $JAVA_VERSION_STRING"

# Extract version number
JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
JAVA_MAJOR=$(echo $JAVA_VERSION | cut -d'.' -f1)
JAVA_MINOR=$(echo $JAVA_VERSION | cut -d'.' -f2)

# Check if it's old format (1.8.x)
if [ "$JAVA_MAJOR" = "1" ]; then
    print_error "Java version is too old"
    echo "         You have: Java 8 (version $JAVA_VERSION)"
    echo "         Required: Java 11 or newer"
    echo ""
    echo "SOLUTION:"
    echo "  1. Download Java 11 or newer from: https://adoptium.net/temurin/releases/"
    echo "  2. Recommended: Eclipse Temurin JRE 11 or 17 (LTS versions)"
    echo "  3. Install and restart this installer"
    echo ""
    echo "WHY: The Hurricane launcher requires Java 11+ features"
    echo ""
    read -p "Press Enter to exit..."
    exit 1
fi

# Check if version is too old (Java 9, 10)
if [ "$JAVA_MAJOR" -lt 11 ]; then
    print_error "Java version is too old"
    echo "         You have: Java $JAVA_MAJOR (version $JAVA_VERSION)"
    echo "         Required: Java 11 or newer"
    echo ""
    echo "SOLUTION:"
    echo "  Download Java 11+ from: https://adoptium.net/temurin/releases/"
    echo ""
    read -p "Press Enter to exit..."
    exit 1
fi

print_success "Java $JAVA_MAJOR meets requirements (11+)"
echo ""

# ============================================================================
# STEP 3: Setup Installation Directory
# ============================================================================
print_step 3 5 "Setting Up Installation Directory"

print_info "Installation path: $INSTALL_DIR"

if [ ! -d "$INSTALL_DIR" ]; then
    print_info "Creating directory..."
    mkdir -p "$INSTALL_DIR" 2>/dev/null
    if [ $? -ne 0 ]; then
        print_error "Failed to create directory: $INSTALL_DIR"
        echo ""
        echo "SOLUTION:"
        echo "  1. Check if you have write permissions"
        echo "  2. Try running with sudo (not recommended)"
        echo "  3. Check disk space"
        echo ""
        read -p "Press Enter to exit..."
        exit 1
    fi
    print_success "Directory created successfully"
else
    print_success "Directory already exists"
fi

cd "$INSTALL_DIR" || {
    print_error "Cannot access directory: $INSTALL_DIR"
    echo ""
    echo "SOLUTION:"
    echo "  Check if the directory exists and you have permissions"
    echo ""
    read -p "Press Enter to exit..."
    exit 1
}
echo ""

# ============================================================================
# STEP 4: Download/Update Launcher
# ============================================================================
print_step 4 5 "Checking Launcher Files"

if [ -f "launcher.jar" ]; then
    print_info "Found existing launcher.jar"
    SIZE=$(stat -f%z "launcher.jar" 2>/dev/null || stat -c%s "launcher.jar" 2>/dev/null)
    print_info "File size: $SIZE bytes"
    
    # Check if file is suspiciously small
    if [ "$SIZE" -lt 10000 ]; then
        print_warning "File seems too small, will re-download"
        rm -f launcher.jar
    fi
fi

if [ ! -f "launcher.jar" ]; then
    print_info "Downloading launcher from: $LAUNCHER_URL"
    print_info "This may take 10-30 seconds..."
    echo ""
    
    # Try download with curl or wget
    if command -v curl &> /dev/null; then
        if curl -L -o launcher.jar "$LAUNCHER_URL" --progress-bar; then
            print_success "Downloaded launcher.jar"
        else
            print_error "Failed to download launcher.jar"
            echo ""
            echo "POSSIBLE CAUSES:"
            echo "  - No internet connection"
            echo "  - Firewall blocking downloads"
            echo "  - GitHub Pages temporarily unavailable"
            echo ""
            echo "SOLUTION:"
            echo "  1. Check your internet connection"
            echo "  2. Try again in a few minutes"
            echo "  3. Manual download: $LAUNCHER_URL"
            echo ""
            read -p "Press Enter to exit..."
            exit 1
        fi
    elif command -v wget &> /dev/null; then
        if wget -O launcher.jar "$LAUNCHER_URL"; then
            print_success "Downloaded launcher.jar"
        else
            print_error "Failed to download launcher.jar"
            echo ""
            echo "Check your internet connection and try again"
            echo ""
            read -p "Press Enter to exit..."
            exit 1
        fi
    else
        print_error "Neither curl nor wget found"
        echo ""
        echo "Please install curl or wget to download files:"
        echo "  Ubuntu/Debian: sudo apt install curl"
        echo "  Fedora/RHEL:   sudo dnf install curl"
        echo "  macOS:         curl is pre-installed"
        echo ""
        read -p "Press Enter to exit..."
        exit 1
    fi
else
    print_success "Using existing launcher"
fi

# Verify downloaded file
if [ ! -f "launcher.jar" ]; then
    print_error "launcher.jar not found after download"
    echo ""
    echo "SOLUTION:"
    echo "  1. Check disk space"
    echo "  2. Check write permissions"
    echo "  3. Try running again"
    echo ""
    read -p "Press Enter to exit..."
    exit 1
fi

FINAL_SIZE=$(stat -f%z "launcher.jar" 2>/dev/null || stat -c%s "launcher.jar" 2>/dev/null)
if [ "$FINAL_SIZE" -lt 10000 ]; then
    print_error "Downloaded file is too small ($FINAL_SIZE bytes)"
    echo "[ERROR] File may be corrupted or incomplete"
    echo ""
    echo "SOLUTION:"
    echo "  1. Delete launcher.jar and try again"
    echo "  2. Check internet connection"
    echo "  3. Try downloading manually from: $LAUNCHER_URL"
    echo ""
    rm -f launcher.jar
    read -p "Press Enter to exit..."
    exit 1
fi

print_success "Launcher verified ($FINAL_SIZE bytes)"
echo ""

# ============================================================================
# STEP 5: Launch Hurricane
# ============================================================================
print_step 5 5 "Starting Hurricane Client"

echo ""
print_info "Remote config: $CONFIG_URL"
print_info "This will download game files on first run (~100-150 MB)"
print_info "Subsequent launches will be much faster"
echo ""
echo "========================================"
echo "           LAUNCHING GAME..."
echo "========================================"
echo ""
echo "Window will remain open after launch for debugging"
echo "Close this window after the game starts successfully"
echo ""
echo "If the game window doesn't appear:"
echo "  - Check if Java created any error dialogs"
echo "  - Look for game window in taskbar/dock"
echo "  - Game may take 30-60 seconds to appear on first launch"
echo ""
echo "----------------------------------------"
echo ""

# Launch the game
java -jar launcher.jar "$CONFIG_URL"
LAUNCH_EXIT_CODE=$?

echo ""
echo "========================================"
echo "         LAUNCH COMPLETED"
echo "========================================"
echo ""

if [ $LAUNCH_EXIT_CODE -eq 0 ]; then
    print_success "Launcher exited normally"
    echo ""
    echo "If game didn't start:"
    echo "  - Game files may still be downloading in background"
    echo "  - Check taskbar/dock for game window"
    echo "  - Wait a few moments and check again"
else
    print_error "Launcher exited with error code: $LAUNCH_EXIT_CODE"
    echo ""
    echo "COMMON ISSUES:"
    echo "  1. Java version incompatible (need Java 11+)"
    echo "  2. Corrupt game files (delete ~/.cache/haven-launcher)"
    echo "  3. Missing dependencies"
    echo "  4. Network issues during file download"
    echo ""
    echo "SOLUTION:"
    echo "  - Delete game cache: ~/.cache/haven-launcher"
    echo "  - Delete launcher.jar and re-run this installer"
    echo "  - Check firewall isn't blocking Java"
    echo ""
fi

echo ""
echo "Installation directory: $INSTALL_DIR"
echo "Cache directory: $HOME/.cache/haven-launcher"
echo ""
echo "Press Enter to close this window..."
read

exit $LAUNCH_EXIT_CODE

