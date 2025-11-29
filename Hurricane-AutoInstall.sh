#!/bin/bash
# Hurricane Client - Self-Contained Auto-Installer
# This single file downloads and runs everything automatically
# No separate downloads needed!

# Configuration
LAUNCHER_URL="https://hafenexplorer.github.io/launcher.jar"
CONFIG_URL="https://hafenexplorer.github.io/launcher.hl"
INSTALL_DIR="$HOME/.local/share/hurricane"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
print_step() {
    echo -e "${YELLOW}[$1/$2] $3${NC}"
}

print_success() {
    echo -e "${GREEN}      $1 [OK]${NC}"
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

# Display header
clear
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   HURRICANE CLIENT LAUNCHER${NC}"
echo -e "${CYAN}   Auto-Installer Version${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Step 1: Check Java
print_step 1 5 "Checking Java installation..."
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1)
    print_success "Java found"
else
    echo ""
    print_error "Java is not installed or not in PATH"
    echo ""
    echo "Please install Java:"
    echo "  Ubuntu/Debian: sudo apt install openjdk-11-jre"
    echo "  Fedora/RHEL: sudo dnf install java-11-openjdk"
    echo "  macOS: brew install openjdk@11"
    echo ""
    read -p "Press Enter to exit..."
    exit 1
fi

# Step 2: Create directory
print_step 2 5 "Setting up Hurricane directory..."
if [ ! -d "$INSTALL_DIR" ]; then
    mkdir -p "$INSTALL_DIR"
    print_success "Created: $INSTALL_DIR"
else
    print_success "Directory exists"
fi

# Step 3: Download launcher.jar
print_step 3 5 "Checking launcher files..."
cd "$INSTALL_DIR"

if [ ! -f "launcher.jar" ]; then
    echo "      Downloading launcher.jar..."
    echo "      This may take a minute..."
    
    if command -v curl &> /dev/null; then
        if curl -L -o launcher.jar "$LAUNCHER_URL" --progress-bar; then
            print_success "Downloaded launcher.jar"
        else
            echo ""
            print_error "Failed to download launcher.jar"
            echo "Please check your internet connection."
            echo ""
            read -p "Press Enter to exit..."
            exit 1
        fi
    elif command -v wget &> /dev/null; then
        if wget -O launcher.jar "$LAUNCHER_URL"; then
            print_success "Downloaded launcher.jar"
        else
            echo ""
            print_error "Failed to download launcher.jar"
            echo "Please check your internet connection."
            echo ""
            read -p "Press Enter to exit..."
            exit 1
        fi
    else
        echo ""
        print_error "Neither curl nor wget found"
        echo "Please install curl or wget to download files."
        echo ""
        read -p "Press Enter to exit..."
        exit 1
    fi
else
    print_success "launcher.jar exists"
fi

# Step 4: Create desktop shortcut
print_step 4 5 "Creating shortcuts..."

# Create .desktop file for Linux
if [ -d "$HOME/.local/share/applications" ]; then
    cat > "$HOME/.local/share/applications/hurricane.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Hurricane
Comment=Hurricane Client for Haven & Hearth
Exec=java -jar "$INSTALL_DIR/launcher.jar" "$CONFIG_URL"
Path=$INSTALL_DIR
Terminal=false
Categories=Game;
EOF
    chmod +x "$HOME/.local/share/applications/hurricane.desktop"
    print_success "Created application menu entry"
fi

# Create launcher script in user bin
if [ -d "$HOME/.local/bin" ]; then
    cat > "$HOME/.local/bin/hurricane" << EOF
#!/bin/bash
cd "$INSTALL_DIR"
java -jar "$INSTALL_DIR/launcher.jar" "$CONFIG_URL"
EOF
    chmod +x "$HOME/.local/bin/hurricane"
    print_success "Created command: hurricane"
fi

# Step 5: Launch
print_step 5 5 "Starting Hurricane..."
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   Launching Game...${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Launch the game using the remote config URL
java -jar "$INSTALL_DIR/launcher.jar" "$CONFIG_URL"

# Check exit status
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   Installation Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Hurricane has been installed to:"
    echo "  $INSTALL_DIR"
    echo ""
    echo "You can run Hurricane by:"
    echo "  - Searching for 'Hurricane' in your application menu"
    echo "  - Running: hurricane (from terminal)"
    echo ""
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}   Launcher exited with an error${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    read -p "Press Enter to exit..."
fi

