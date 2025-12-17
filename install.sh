#!/bin/bash

# Sway Setup Installer - VM Optimized Version
# Fixed to handle installation failures gracefully

set -e

# Command line options
ONLY_CONFIG=false
EXPORT_PACKAGES=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --only-config)
            ONLY_CONFIG=true
            shift
            ;;
        --export-packages)
            EXPORT_PACKAGES=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "  --only-config      Only copy config files (skip packages)"
            echo "  --export-packages  Export package lists for different distros and exit"
            echo "  --help            Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/sway"
TEMP_DIR="/tmp/sway_$$"
LOG_FILE="$HOME/sway-install.log"

# Logging and cleanup
exec > >(tee -a "$LOG_FILE") 2>&1
trap "rm -rf $TEMP_DIR" EXIT

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

die() { echo -e "${RED}ERROR: $*${NC}" >&2; exit 1; }
msg() { echo -e "${CYAN}$*${NC}"; }

# Export package lists for different distros
export_packages() {
    echo "=== Sway Setup - Package Lists for Different Distributions ==="
    echo

    # Combine all packages
    local all_packages=(
        "sway" "swayidle" "gtklock" "swaybg" "waybar"
        "xwayland" "build-essential"
        "wofi" "wmenu" "foot" "sway-notification-center" "autotiling"
        "grim" "slurp" "wl-clipboard" "cliphist"
        "brightnessctl" "playerctl"
        "wlr-randr"
        "xdg-desktop-portal-wlr" "swappy" "wtype"
        "nwg-look" "network-manager-gnome" "lxpolkit"
        "thunar" "thunar-archive-plugin" "thunar-volman"
        "gvfs-backends" "dialog" "mtools" "smbclient" "cifs-utils" "unzip"
        "pavucontrol" "pulsemixer" "pamixer" "pipewire-audio"
        "avahi-daemon" "acpi" "acpid"
        "fd-find" "xdg-user-dirs-gtk"
        "kanshi" "eog" "nwg-displays"
        "gawk"
        "libnotify-bin" "libnotify-dev" "libusb-0.1-4"
        "cmake" "meson" "ninja-build" "curl" "pkg-config" "wget"
        "fonts-recommended" "fonts-font-awesome" "fonts-noto-color-emoji"
    )

    echo "DEBIAN/UBUNTU:"
    echo "sudo apt install ${all_packages[*]}"
    echo
}

# Check if we should export packages and exit
if [ "$EXPORT_PACKAGES" = true ]; then
    export_packages
    exit 0
fi

# Banner
clear
echo -e "${CYAN}"
echo " +-+-+-+-+-+-+-+-+-+-+-+-+ "
echo " |S|w|a|y| |S|e|t|u|p|    | "
echo " +-+-+-+-+-+-+-+-+-+-+-+-+ "
echo " |W|a|y|l|a|n|d| |W|M|    | "
echo " +-+-+-+-+-+-+-+-+-+-+-+-+ "
echo -e "${NC}\n"

read -p "Install Sway? (y/n) " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 1

# Update system
if [ "$ONLY_CONFIG" = false ]; then
    msg "Updating system..."
    sudo apt-get update && sudo apt-get upgrade -y
else
    msg "Skipping system update (--only-config mode)"
fi

# Package groups for better organization
PACKAGES_CORE=(
    sway swayidle gtklock swaybg waybar
    xwayland build-essential
)

PACKAGES_SWAY=(
    wofi wmenu foot sway-notification-center autotiling
    grim slurp wl-clipboard cliphist
    brightnessctl playerctl
    wlr-randr
    xdg-desktop-portal-wlr swappy wtype
)

PACKAGES_UI=(
    nwg-look network-manager-gnome lxpolkit
)

PACKAGES_FILE_MANAGER=(
    thunar thunar-archive-plugin thunar-volman
    gvfs-backends dialog mtools smbclient cifs-utils unzip
)

PACKAGES_AUDIO=(
    pavucontrol pulsemixer pamixer pipewire-audio
)

PACKAGES_UTILITIES=(
    avahi-daemon acpi acpid
    fd-find xdg-user-dirs-gtk
    kanshi eog nwg-displays
    gawk
    libnotify-bin libnotify-dev libusb-0.1-4
)

PACKAGES_BUILD=(
    cmake meson ninja-build curl pkg-config wget
)

PACKAGES_FONTS=(
    fonts-recommended fonts-font-awesome fonts-noto-color-emoji
)

# Install packages by group
if [ "$ONLY_CONFIG" = false ]; then
    msg "Installing core Sway packages..."
    sudo apt-get install -y "${PACKAGES_CORE[@]}" || die "Failed to install core packages"

    msg "Installing Sway components..."
    sudo apt-get install -y "${PACKAGES_SWAY[@]}" || die "Failed to install Sway packages"

    msg "Installing UI components..."
    sudo apt-get install -y "${PACKAGES_UI[@]}" || die "Failed to install UI packages"

    msg "Installing file manager..."
    sudo apt-get install -y "${PACKAGES_FILE_MANAGER[@]}" || die "Failed to install file manager"

    msg "Installing audio support..."
    sudo apt-get install -y "${PACKAGES_AUDIO[@]}" || die "Failed to install audio packages"

    msg "Installing build tools..."
    sudo apt-get install -y "${PACKAGES_BUILD[@]}" || die "Failed to install build tools"

    msg "Installing system utilities..."
    sudo apt-get install -y "${PACKAGES_UTILITIES[@]}" || die "Failed to install utilities"

    # Try firefox-esr first (Debian), then firefox (Ubuntu)
    sudo apt-get install -y firefox-esr 2>/dev/null || sudo apt-get install -y firefox 2>/dev/null || msg "Note: firefox not available, skipping..."

    msg "Installing fonts..."
    sudo apt-get install -y "${PACKAGES_FONTS[@]}" || die "Failed to install fonts"

    # Enable services
    sudo systemctl enable avahi-daemon acpid
else
    msg "Skipping package installation (--only-config mode)"
fi

# Handle existing config
if [ -d "$CONFIG_DIR" ]; then
    clear
    read -p "Found existing Sway config. Backup? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mv "$CONFIG_DIR" "$CONFIG_DIR.bak.$(date +%s)"
        msg "Backed up existing config"
    else
        clear
        read -p "Overwrite without backup? (y/n) " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] || die "Installation cancelled"
        rm -rf "$CONFIG_DIR"
    fi
fi

# Copy configs
msg "Setting up configuration..."
mkdir -p "$CONFIG_DIR"

# Check if config directory exists in script location
if [ -d "$SCRIPT_DIR/config" ]; then
    cp -r "$SCRIPT_DIR"/config/* "$CONFIG_DIR"/ || die "Failed to copy configs"
else
    msg "WARNING: Config directory not found at $SCRIPT_DIR/config"
    msg "You will need to copy configs manually from the git repository"
fi

# Create symlinks only for apps that require default locations
ln -sf ~/.config/sway/gtklock ~/.config/gtklock 2>/dev/null || true
ln -sf ~/.config/sway/foot ~/.config/foot 2>/dev/null || true

# Setup directories
xdg-user-dirs-update
mkdir -p ~/Screenshots

# Butterscript helper - with error handling
get_script() {
    local script_url="https://codeberg.org/justaguylinux/butterscripts/raw/branch/main/$1"
    msg "Downloading $1..."
    if wget -qO- "$script_url" | bash; then
        msg "Successfully installed $1"
        return 0
    else
        msg "WARNING: Failed to install $1 - continuing anyway"
        return 1
    fi
}

# Install essential components
if [ "$ONLY_CONFIG" = false ]; then
    mkdir -p "$TEMP_DIR" && cd "$TEMP_DIR"

    msg "Installing external tools (these may fail in VM - that's OK)..."
    echo

    # Try each installation but don't fail if they error
    msg "Attempting wezterm installation..."
    get_script "wezterm/install_wezterm.sh" || true
    
    msg "Attempting rofi wayland installation..."
    get_script "setup/install_rofi_wayland.sh" || true

    msg "Attempting fonts installation..."
    get_script "theming/install_nerdfonts.sh" || true

    msg "Attempting themes installation..."
    get_script "theming/install_theme.sh" || true

    msg "Downloading wallpaper directory..."
    cd "$CONFIG_DIR"
    if git clone --depth 1 --filter=blob:none --sparse https://codeberg.org/justaguylinux/butterscripts.git "$TEMP_DIR/butterscripts-wallpaper"; then
        cd "$TEMP_DIR/butterscripts-wallpaper"
        if git sparse-checkout set wallpaper; then
            cp -r wallpaper "$CONFIG_DIR"/ || msg "Failed to copy wallpaper directory"
        fi
    else
        msg "WARNING: Failed to download wallpapers - you can add them manually later"
    fi
    
    msg "Downloading display manager installer..."
    if wget -O "$TEMP_DIR/install_lightdm.sh" "https://codeberg.org/justaguylinux/butterscripts/raw/branch/main/system/install_lightdm.sh"; then
        chmod +x "$TEMP_DIR/install_lightdm.sh"
        msg "Running display manager installer..."
        bash "$TEMP_DIR/install_lightdm.sh" || msg "Display manager installation skipped or failed"
    else
        msg "WARNING: Could not download display manager installer"
    fi

    # NVIDIA setup (auto-detects GPU and drivers)
    if [ -f "$SCRIPT_DIR/nvidia-setup.sh" ]; then
        msg "Checking for NVIDIA GPU configuration..."
        bash "$SCRIPT_DIR/nvidia-setup.sh" || true
    else
        msg "NVIDIA setup script not found, skipping..."
    fi

    # Optional tools
    clear
    read -p "Install optional tools (browsers, editors, etc)? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        msg "Downloading optional tools installer..."
        if wget -O "$TEMP_DIR/optional_tools.sh" "https://codeberg.org/justaguylinux/butterscripts/raw/branch/main/setup/optional_tools.sh"; then
            chmod +x "$TEMP_DIR/optional_tools.sh"
            msg "Running optional tools installer..."
            bash "$TEMP_DIR/optional_tools.sh" || msg "Optional tools installation skipped or failed"
        fi
    fi
else
    msg "Skipping external tool installation (--only-config mode)"
fi

# Done
echo -e "\n${GREEN}Installation complete!${NC}"
echo
echo "Next steps:"
echo "1. Log out of your current session"
echo "2. At the login screen, select 'Sway' from the session menu"
echo "3. Log in"
echo "4. Press Super+Space for application launcher"
echo "5. Press Super+Shift+n for notification center"
echo
echo "If some themes or fonts didn't install properly (common in VMs),"
echo "you can install them manually later."
echo
echo "Installation log: $LOG_FILE"