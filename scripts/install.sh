#!/bin/bash
set -e

# ==============================================================================
# LaterBox Universal Installer (macOS & Linux)
# Website: https://laterbox.dev
# Repository: https://github.com/Chaste-Djaziri/laterbox
# ==============================================================================

# ANSI Color Codes
BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_banner() {
  echo -e "${CYAN}${BOLD}"
  echo "  _          _             ____            "
  echo " | |    __ _| |_ ___ _ __ | __ )  _____  __"
  echo " | |   / _\` | __/ _ \ '__||  _ \ / _ \ \/ /"
  echo " | |__| (_| | ||  __/ |   | |_) | (_) >  < "
  echo " |_____\__,_|\__\___|_|   |____/ \___/_/\_\\"
  echo -e "${NC}"
  echo -e "${BOLD}Your smart reading inbox and autonomous content library.${NC}"
  echo -e "${CYAN}https://laterbox.dev${NC}\n"
}

print_banner

OS="$(uname -s)"
ARCH="$(uname -m)"

echo -e "${BOLD}[1/4] Detecting environment...${NC}"
echo "  • Operating System: $OS"
echo "  • Architecture:     $ARCH"

# Determine Latest Release download URLs
GITHUB_REPO="Chaste-Djaziri/laterbox"
PRIMARY_URL="https://laterbox.dev/downloads"
FALLBACK_URL="https://github.com/${GITHUB_REPO}/releases/latest/download"

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# ------------------------------------------------------------------------------
# macOS Installation
# ------------------------------------------------------------------------------
if [ "$OS" = "Darwin" ]; then
  echo -e "\n${BOLD}[2/4] Downloading LaterBox for macOS...${NC}"
  
  if [ "$ARCH" = "arm64" ]; then
    DMG_NAME="laterbox-macos-apple-silicon.dmg"
  else
    DMG_NAME="laterbox-macos-intel.dmg"
  fi
  
  DOWNLOAD_URL="${PRIMARY_URL}/${DMG_NAME}"
  TARGET_DMG="${TMP_DIR}/${DMG_NAME}"

  echo "  • Fetching: ${DOWNLOAD_URL}"
  if ! curl -fsSL "$DOWNLOAD_URL" -o "$TARGET_DMG"; then
    echo -e "${YELLOW}Retrying via GitHub direct release...${NC}"
    DOWNLOAD_URL="${FALLBACK_URL}/${DMG_NAME}"
    if ! curl -fsSL "$DOWNLOAD_URL" -o "$TARGET_DMG"; then
      echo -e "${YELLOW}Falling back to universal release asset...${NC}"
      curl -fsSL "${PRIMARY_URL}/laterbox-macos.dmg" -o "$TARGET_DMG" || curl -fsSL "${FALLBACK_URL}/laterbox-macos.dmg" -o "$TARGET_DMG"
    fi
  fi

  echo -e "\n${BOLD}[3/4] Installing LaterBox into Applications...${NC}"
  MOUNT_DIR="${TMP_DIR}/mount"
  mkdir -p "$MOUNT_DIR"
  
  # Attach DMG
  hdiutil attach "$TARGET_DMG" -mountpoint "$MOUNT_DIR" -nobrowse -quiet
  
  APP_SRC="$(find "$MOUNT_DIR" -maxdepth 2 -name "laterbox.app" | head -n 1)"
  if [ -z "$APP_SRC" ]; then
    APP_SRC="$(find "$MOUNT_DIR" -maxdepth 2 -name "*.app" | head -n 1)"
  fi

  if [ -n "$APP_SRC" ]; then
    DEST_DIR="/Applications"
    if [ ! -w "/Applications" ]; then
      DEST_DIR="$HOME/Applications"
      mkdir -p "$DEST_DIR"
    fi
    
    echo "  • Installing to: ${DEST_DIR}/laterbox.app"
    rm -rf "${DEST_DIR}/laterbox.app"
    cp -R "$APP_SRC" "${DEST_DIR}/laterbox.app"
    
    # Detach DMG
    hdiutil detach "$MOUNT_DIR" -quiet || true
    
    # Remove quarantine attribute
    xattr -rd com.apple.quarantine "${DEST_DIR}/laterbox.app" 2>/dev/null || true
    
    echo -e "\n${BOLD}[4/4] Configuring CLI command 'laterbox'...${NC}"
    CLI_TARGET="/usr/local/bin"
    if [ ! -w "$CLI_TARGET" ] || [ ! -d "$CLI_TARGET" ]; then
      CLI_TARGET="$HOME/.local/bin"
      mkdir -p "$CLI_TARGET"
    fi
    
    cat <<EOF > "${CLI_TARGET}/laterbox"
#!/bin/bash
open -a "${DEST_DIR}/laterbox.app" --args "\$@"
EOF
    chmod +x "${CLI_TARGET}/laterbox"
    
    echo -e "${GREEN}${BOLD}✔ LaterBox successfully installed!${NC}"
    echo -e "  • Open from Launchpad or run: ${CYAN}laterbox${NC} in your terminal."
  else
    hdiutil detach "$MOUNT_DIR" -quiet || true
    echo -e "${RED}Failed to locate LaterBox.app in the downloaded disk image.${NC}"
    exit 1
  fi

# ------------------------------------------------------------------------------
# Linux Installation
# ------------------------------------------------------------------------------
elif [ "$OS" = "Linux" ]; then
  echo -e "\n${BOLD}[2/4] Downloading LaterBox for Linux...${NC}"
  TAR_NAME="laterbox-linux-x64.tar.gz"
  DOWNLOAD_URL="${PRIMARY_URL}/${TAR_NAME}"
  TARGET_TAR="${TMP_DIR}/${TAR_NAME}"

  echo "  • Fetching: ${DOWNLOAD_URL}"
  if ! curl -fsSL "$DOWNLOAD_URL" -o "$TARGET_TAR"; then
    echo -e "${YELLOW}Retrying via GitHub direct release...${NC}"
    curl -fsSL "${FALLBACK_URL}/${TAR_NAME}" -o "$TARGET_TAR"
  fi

  echo -e "\n${BOLD}[3/4] Installing LaterBox...${NC}"
  INSTALL_DIR="$HOME/.local/share/laterbox"
  mkdir -p "$INSTALL_DIR"
  rm -rf "${INSTALL_DIR:?}"/*
  tar -xzf "$TARGET_TAR" -C "$INSTALL_DIR"

  echo -e "\n${BOLD}[4/4] Setting up Desktop entry and CLI symlink...${NC}"
  BIN_DIR="$HOME/.local/bin"
  mkdir -p "$BIN_DIR"
  ln -sf "${INSTALL_DIR}/laterbox" "${BIN_DIR}/laterbox"
  chmod +x "${INSTALL_DIR}/laterbox" 2>/dev/null || true

  # Create .desktop launcher
  DESKTOP_DIR="$HOME/.local/share/applications"
  mkdir -p "$DESKTOP_DIR"
  cat <<EOF > "${DESKTOP_DIR}/laterbox.desktop"
[Desktop Entry]
Name=LaterBox
Comment=Smart reading inbox and autonomous content library
Exec=${INSTALL_DIR}/laterbox %U
Icon=${INSTALL_DIR}/data/flutter_assets/assets/branding/laterbox-icon.png
Terminal=false
Type=Application
Categories=Utility;Office;
MimeType=x-scheme-handler/laterbox;
EOF

  chmod +x "${DESKTOP_DIR}/laterbox.desktop"
  update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

  echo -e "${GREEN}${BOLD}✔ LaterBox successfully installed!${NC}"
  echo -e "  • Run: ${CYAN}laterbox${NC} or launch from your application menu."
  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo -e "${YELLOW}  Note: Add ~/.local/bin to your PATH to use the 'laterbox' CLI command:${NC}"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
  fi

else
  echo -e "${RED}Unsupported Operating System: $OS${NC}"
  echo "Please download the installer directly from https://laterbox.dev/download"
  exit 1
fi
