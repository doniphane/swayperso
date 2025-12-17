#!/bin/bash

# ============================================================================
# SCRIPT COMPLET D'INSTALLATION ET CONFIGURATION SWAY
# ============================================================================
# Combine:
#   - Installation de Sway et dépendances
#   - Configuration Waybar complète (CPU, RAM, IP, WiFi, Son, etc.)
#   - Configuration Rofi
#   - Correction des lags navigateur
#   - Tous les raccourcis et personnalisations
# ============================================================================

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

msg() { echo -e "${CYAN}>>> $*${NC}"; }
success() { echo -e "${GREEN}✓ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠ $*${NC}"; }
error() { echo -e "${RED}✗ $*${NC}" >&2; exit 1; }
section() { echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"; echo -e "${BLUE}║ $*${NC}"; echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"; }

# Vérifier qu'on n'est pas root
[ "$EUID" -eq 0 ] && error "Ne pas exécuter ce script en root!"

# Chemins
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/sway"
WAYBAR_DIR="$CONFIG_DIR/waybar"
ROFI_DIR="$CONFIG_DIR/rofi"
SCRIPTS_DIR="$CONFIG_DIR/scripts"
TEMP_DIR="/tmp/sway_install_$$"
LOG_FILE="$HOME/sway-complete-install.log"

# Logging
exec > >(tee -a "$LOG_FILE") 2>&1
trap "rm -rf $TEMP_DIR" EXIT

# Banner principal
clear
echo -e "${MAGENTA}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║     SSSSS   W     W    AAA    Y     Y                           ║
║    S        W     W   A   A    Y   Y                            ║
║     SSSS    W  W  W  AAAAAAA    Y Y                             ║
║         S   W W W W  A     A     Y                              ║
║    SSSSS     W   W   A     A     Y                              ║
║                                                                  ║
║           INSTALLATION ET CONFIGURATION COMPLÈTE                ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${CYAN}Ce script va installer et configurer:${NC}"
echo "  • Sway (gestionnaire de fenêtres Wayland)"
echo "  • Waybar (barre avec CPU, RAM, IP, WiFi, Son, Batterie, Langue)"
echo "  • Rofi (lanceur d'applications)"
echo "  • Tous les drivers graphiques nécessaires"
echo "  • Correction des lags navigateur"
echo "  • Configuration résolution 1920x1080"
echo "  • Aide raccourcis intégrée (Super+1)"
echo
read -p "Continuer? (o/n) " -n 1 -r
echo
[[ ! $REPLY =~ ^[OoYy]$ ]] && exit 0

# ============================================================================
# PARTIE 1: INSTALLATION DES PAQUETS
# ============================================================================
section "PARTIE 1/4: Installation des paquets"

msg "Mise à jour du système..."
sudo apt-get update && sudo apt-get upgrade -y
success "Système mis à jour"

# Paquets Sway de base
PACKAGES_CORE=(
    sway swayidle swaylock swaybg waybar
    xwayland build-essential
)

# Composants Sway
PACKAGES_SWAY=(
    wofi wmenu foot rofi sway-notification-center
    grim slurp wl-clipboard cliphist
    brightnessctl playerctl
    wlr-randr mako
    xdg-desktop-portal-wlr swappy wtype
)

# Interface utilisateur
PACKAGES_UI=(
    thunar thunar-archive-plugin thunar-volman
    pavucontrol network-manager-gnome
    gvfs-backends dialog mtools smbclient cifs-utils unzip
)

# Audio et système
PACKAGES_AUDIO=(
    pipewire pipewire-pulse wireplumber
    pulsemixer pamixer pulseaudio-utils
)

PACKAGES_UTILITIES=(
    avahi-daemon acpi acpid
    fd-find xdg-user-dirs-gtk
    eog
    gawk jq
    libnotify-bin libnotify-dev
)

# Build tools
PACKAGES_BUILD=(
    cmake meson ninja-build curl pkg-config wget
)

# Fonts
PACKAGES_FONTS=(
    fonts-recommended fonts-font-awesome fonts-noto-color-emoji
    fonts-liberation fonts-liberation2
)

# ========== PAQUETS GRAPHIQUES (CORRECTION LAG) ==========
PACKAGES_GRAPHICS=(
    # Librairies Wayland
    libwayland-client0 libwayland-cursor0 libwayland-egl1 libwayland-server0
    
    # Mesa et OpenGL
    libegl1-mesa libegl1-mesa-dev libgl1-mesa-dri libgl1-mesa-glx
    libgles2-mesa libglx-mesa0 mesa-utils mesa-vulkan-drivers
    mesa-va-drivers mesa-vdpau-drivers
    
    # DRM et GBM
    libdrm2 libdrm-amdgpu1 libdrm-intel1 libdrm-nouveau2 libdrm-radeon1
    libgbm1
    
    # Accélération vidéo
    va-driver-all vdpau-driver-all libva2 libvdpau1 vainfo
    
    # Vulkan
    libvulkan1 vulkan-tools
    
    # GTK/Qt Wayland
    libgtk-3-0 libgtk-4-1 qt5-wayland qt6-wayland
    
    # Codecs
    gstreamer1.0-plugins-base gstreamer1.0-plugins-good
    gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly
    gstreamer1.0-libav gstreamer1.0-vaapi
    
    # Support supplémentaire
    libfreetype6 libfontconfig1 libdbus-glib-1-2 libxt6
)

# Drivers Intel
PACKAGES_INTEL=(
    intel-media-va-driver i965-va-driver libva-glx2
)

# Installation par groupes
msg "Installation des paquets Sway de base..."
sudo apt-get install -y "${PACKAGES_CORE[@]}" || warn "Certains paquets core n'ont pas pu être installés"

msg "Installation des composants Sway..."
sudo apt-get install -y "${PACKAGES_SWAY[@]}" || warn "Certains paquets Sway n'ont pas pu être installés"

msg "Installation de l'interface utilisateur..."
sudo apt-get install -y "${PACKAGES_UI[@]}" || warn "Certains paquets UI n'ont pas pu être installés"

msg "Installation du support audio..."
sudo apt-get install -y "${PACKAGES_AUDIO[@]}" || warn "Certains paquets audio n'ont pas pu être installés"

msg "Installation des utilitaires..."
sudo apt-get install -y "${PACKAGES_UTILITIES[@]}" || warn "Certains paquets utilitaires n'ont pas pu être installés"

msg "Installation des outils de build..."
sudo apt-get install -y "${PACKAGES_BUILD[@]}" || warn "Certains paquets build n'ont pas pu être installés"

msg "Installation des polices..."
sudo apt-get install -y "${PACKAGES_FONTS[@]}" || warn "Certaines polices n'ont pas pu être installées"

msg "Installation des paquets graphiques (correction lag)..."
sudo apt-get install -y "${PACKAGES_GRAPHICS[@]}" || warn "Certains paquets graphiques n'ont pas pu être installés"

# Navigateur
msg "Installation du navigateur..."
sudo apt-get install -y firefox-esr 2>/dev/null || sudo apt-get install -y firefox 2>/dev/null || warn "Firefox non disponible"

# Détection GPU et installation drivers spécifiques
GPU_INFO=$(lspci | grep -i 'vga\|3d\|display')
msg "GPU détecté: $GPU_INFO"

if echo "$GPU_INFO" | grep -iq "intel"; then
    msg "Installation des drivers Intel..."
    sudo apt-get install -y "${PACKAGES_INTEL[@]}" || warn "Certains drivers Intel n'ont pas pu être installés"
    success "Drivers Intel installés"
fi

if echo "$GPU_INFO" | grep -iq "nvidia"; then
    warn "GPU NVIDIA détecté - Installez manuellement: sudo apt install nvidia-driver"
fi

# Services
sudo systemctl enable avahi-daemon acpid 2>/dev/null || true

success "Installation des paquets terminée"

# ============================================================================
# PARTIE 2: CRÉATION DES RÉPERTOIRES ET SCRIPTS
# ============================================================================
section "PARTIE 2/4: Configuration des fichiers"

msg "Création des répertoires..."
mkdir -p "$CONFIG_DIR"
mkdir -p "$WAYBAR_DIR"
mkdir -p "$ROFI_DIR"
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$HOME/Screenshots"
mkdir -p "$HOME/.config/environment.d"
mkdir -p "$HOME/.local/share/applications"
xdg-user-dirs-update
success "Répertoires créés"

# ========== SCRIPTS WAYBAR ==========
msg "Création des scripts Waybar..."

# Script CPU
cat > "$SCRIPTS_DIR/cpu.sh" << 'EOF'
#!/bin/bash
cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
printf " %.0f%%" "$cpu_usage"
EOF
chmod +x "$SCRIPTS_DIR/cpu.sh"

# Script RAM
cat > "$SCRIPTS_DIR/ram.sh" << 'EOF'
#!/bin/bash
mem_info=$(free -m | awk 'NR==2{printf " %.0f%%", $3*100/$2}')
echo "$mem_info"
EOF
chmod +x "$SCRIPTS_DIR/ram.sh"

# Script IP
cat > "$SCRIPTS_DIR/ip.sh" << 'EOF'
#!/bin/bash
ip_addr=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
if [ -z "$ip_addr" ]; then
    echo " Pas d'IP"
else
    echo " $ip_addr"
fi
EOF
chmod +x "$SCRIPTS_DIR/ip.sh"

# Script langue clavier
cat > "$SCRIPTS_DIR/keyboard-layout.sh" << 'EOF'
#!/bin/bash
current=$(swaymsg -t get_inputs | jq -r '.[] | select(.type=="keyboard") | .xkb_active_layout_name' | head -n1)
if [[ "$current" == *"French"* ]] || [[ "$current" == *"fr"* ]]; then
    echo " FR"
elif [[ "$current" == *"English"* ]] || [[ "$current" == *"us"* ]]; then
    echo " EN"
else
    echo " ${current:0:2}"
fi
EOF
chmod +x "$SCRIPTS_DIR/keyboard-layout.sh"

# Script toggle clavier
cat > "$SCRIPTS_DIR/toggle-keyboard.sh" << 'EOF'
#!/bin/bash
current=$(swaymsg -t get_inputs | jq -r '.[] | select(.type=="keyboard") | .xkb_active_layout_name' | head -n1)
if [[ "$current" == *"French"* ]] || [[ "$current" == *"fr"* ]]; then
    swaymsg input type:keyboard xkb_layout us
    notify-send "Clavier" "Disposition: English (US)" -t 2000
else
    swaymsg input type:keyboard xkb_layout fr
    notify-send "Clavier" "Disposition: Français" -t 2000
fi
EOF
chmod +x "$SCRIPTS_DIR/toggle-keyboard.sh"

# Script aide
cat > "$SCRIPTS_DIR/help.sh" << 'EOF'
#!/bin/bash
rofi -e "
╔══════════════════════════════════════════════════════════╗
║           RACCOURCIS CLAVIER SWAY                        ║
╚══════════════════════════════════════════════════════════╝

APPLICATIONS
  Super + Entrée       Terminal
  Super + Espace       Rofi (lancer applications)
  Super + E            Thunar (gestionnaire de fichiers)
  Super + 1            Afficher cette aide
  
FENÊTRES
  Super + Q            Fermer fenêtre
  Super + F            Plein écran
  Super + Shift+Espace Basculer flottant/ancré
  Super + H/J/K/L      Naviguer entre fenêtres
  Super + Shift+H/J/K/L Déplacer fenêtre
  
ESPACES DE TRAVAIL
  Super + 1-9          Aller à l'espace N
  Super + Shift+1-9    Déplacer vers l'espace N
  
DISPOSITION
  Super + B            Split horizontal
  Super + V            Split vertical
  Super + S            Mode empilement
  Super + W            Mode onglets
  Super + R            Mode redimensionnement
  
SYSTÈME
  Super + Shift+R      Recharger configuration
  Super + Shift+E      Quitter Sway
  Super + X            Verrouiller écran
  Print                Capture d'écran complète
  Super + Print        Capture d'écran zone
  
MULTIMÉDIA
  XF86AudioRaiseVolume  Volume +
  XF86AudioLowerVolume  Volume -
  XF86AudioMute         Muet
  XF86MonBrightnessUp   Luminosité +
  XF86MonBrightnessDown Luminosité -

WAYBAR (INTERACTIONS)
  Clic sur          Changer langue clavier
  Clic sur        Muet/démuet
  Scroll sur      Ajuster volume
  Clic sur        Gérer WiFi
  Clic droit sur  Scanner réseaux
" -theme ~/.config/sway/rofi/theme.rasi
EOF
chmod +x "$SCRIPTS_DIR/help.sh"

success "Scripts créés"

# ============================================================================
# PARTIE 3: FICHIERS DE CONFIGURATION
# ============================================================================
section "PARTIE 3/4: Création des configurations"

# ========== CONFIGURATION SWAY ==========
msg "Création de la configuration Sway..."

cat > "$CONFIG_DIR/config" << 'EOF'
# Configuration Sway complète

### Variables
set $mod Mod4
set $left h
set $down j
set $up k
set $right l
set $term foot
set $menu rofi -show drun -show-icons
set $config_dir ~/.config/sway

### Configuration de sortie
output * resolution 1920x1080 position 0,0
output * bg #00141d solid_color

### Configuration d'entrée
input type:touchpad {
    dwt enabled
    tap enabled
    natural_scroll enabled
    middle_emulation enabled
}

input type:keyboard {
    xkb_layout "fr,us"
    xkb_options "grp:alt_shift_toggle,caps:escape"
    repeat_delay 300
    repeat_rate 50
}

### Idle et verrouillage
exec swayidle -w \
    timeout 600 'swaylock -f -c 000000' \
    timeout 900 'swaymsg "output * dpms off"' \
    resume 'swaymsg "output * dpms on"' \
    before-sleep 'swaylock -f -c 000000'

### Raccourcis clavier de base
bindsym $mod+Return exec $term
bindsym $mod+q kill
bindsym $mod+space exec $menu
bindsym $mod+Shift+r reload
bindsym $mod+Shift+e exec swaynag -t warning -m 'Quitter Sway?' -B 'Oui' 'swaymsg exit'
bindsym $mod+x exec swaylock -f -c 000000
floating_modifier $mod normal

# Aide (Super+1)
bindsym $mod+1 exec $config_dir/scripts/help.sh

# Thunar (Super+E)
bindsym $mod+e exec thunar

### Navigation
bindsym $mod+$left focus left
bindsym $mod+$down focus down
bindsym $mod+$up focus up
bindsym $mod+$right focus right
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

### Déplacer les fenêtres
bindsym $mod+Shift+$left move left
bindsym $mod+Shift+$down move down
bindsym $mod+Shift+$up move up
bindsym $mod+Shift+$right move right
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

### Espaces de travail (clavier français)
bindsym $mod+ampersand workspace number 1
bindsym $mod+eacute workspace number 2
bindsym $mod+quotedbl workspace number 3
bindsym $mod+apostrophe workspace number 4
bindsym $mod+parenleft workspace number 5
bindsym $mod+minus workspace number 6
bindsym $mod+egrave workspace number 7
bindsym $mod+underscore workspace number 8
bindsym $mod+ccedilla workspace number 9
bindsym $mod+agrave workspace number 10

bindsym $mod+Shift+ampersand move container to workspace number 1
bindsym $mod+Shift+eacute move container to workspace number 2
bindsym $mod+Shift+quotedbl move container to workspace number 3
bindsym $mod+Shift+apostrophe move container to workspace number 4
bindsym $mod+Shift+5 move container to workspace number 5
bindsym $mod+Shift+minus move container to workspace number 6
bindsym $mod+Shift+egrave move container to workspace number 7
bindsym $mod+Shift+underscore move container to workspace number 8
bindsym $mod+Shift+ccedilla move container to workspace number 9
bindsym $mod+Shift+agrave move container to workspace number 10

### Disposition
bindsym $mod+b splith
bindsym $mod+v splitv
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+t layout toggle split
bindsym $mod+f fullscreen
bindsym $mod+Shift+space floating toggle
bindsym $mod+a focus parent

### Redimensionner
mode "resize" {
    bindsym $left resize shrink width 10px
    bindsym $down resize grow height 10px
    bindsym $up resize shrink height 10px
    bindsym $right resize grow width 10px
    bindsym Left resize shrink width 10px
    bindsym Down resize grow height 10px
    bindsym Up resize shrink height 10px
    bindsym Right resize grow width 10px
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+r mode "resize"

### Captures d'écran
bindsym Print exec grim ~/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && notify-send "Capture d'écran" "Image enregistrée" -t 2000
bindsym $mod+Print exec grim -g "$(slurp)" ~/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && notify-send "Capture zone" "Image enregistrée" -t 2000
bindsym Shift+Print exec grim -g "$(slurp)" - | wl-copy && notify-send "Capture zone" "Copié dans presse-papier" -t 2000

### Contrôles multimédia
bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5% && notify-send -t 1000 "Volume" "$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+(?=%)' | head -n1)%"
bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5% && notify-send -t 1000 "Volume" "$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+(?=%)' | head -n1)%"
bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle && notify-send -t 1000 "Volume" "Muet basculé"
bindsym XF86MonBrightnessUp exec brightnessctl set +5%
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-
bindsym XF86AudioPlay exec playerctl play-pause
bindsym XF86AudioNext exec playerctl next
bindsym XF86AudioPrev exec playerctl previous

### Apparence
font pango:JetBrainsMono Nerd Font 10
default_border pixel 2
default_floating_border pixel 2
gaps inner 10
gaps outer 5
seat * xcursor_theme default 24

# Couleurs
set $bg #00141d
set $fg #FFFFFF
set $gray #1a1a1a
set $cyan #b3e5fc
set $barbie #4fc3f7
set $blue #80bfff

client.focused          $barbie  $cyan   $gray   $blue     $barbie
client.focused_inactive $gray    $bg     $fg     $bg       $gray
client.unfocused        $gray    $bg     $fg     $bg       $gray
client.urgent           $blue    $blue   $bg     $blue     $blue

### Applications au démarrage
exec_always pkill waybar; waybar -c ~/.config/sway/waybar/config -s ~/.config/sway/waybar/style.css
exec mako
exec nm-applet --indicator
exec wl-paste --watch cliphist store

# Import variables d'environnement
exec systemctl --user import-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK MOZ_ENABLE_WAYLAND QT_QPA_PLATFORM GDK_BACKEND
exec dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK MOZ_ENABLE_WAYLAND QT_QPA_PLATFORM GDK_BACKEND

### Fenêtres flottantes
for_window [app_id="pavucontrol"] floating enable
for_window [app_id="nm-connection-editor"] floating enable
for_window [title="Aide - Raccourcis"] floating enable
for_window [app_id="mpv"] floating enable
for_window [app_id="eog"] floating enable
EOF

success "Configuration Sway créée"

# ========== CONFIGURATION WAYBAR ==========
msg "Création de la configuration Waybar..."

cat > "$WAYBAR_DIR/config" << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 35,
    "spacing": 5,
    
    "modules-left": ["sway/workspaces", "sway/mode", "sway/window"],
    "modules-center": ["clock"],
    "modules-right": ["custom/keyboard", "custom/ip", "custom/cpu", "custom/ram", "pulseaudio", "network", "battery", "tray"],

    "sway/workspaces": {
        "disable-scroll": false,
        "all-outputs": true,
        "format": "{name}",
        "persistent_workspaces": {
            "1": [],
            "2": []
        }
    },

    "sway/mode": {
        "format": "<span style=\"italic\">  {}</span>"
    },

    "sway/window": {
        "format": "{}",
        "max-length": 50,
        "tooltip": false
    },

    "clock": {
        "interval": 1,
        "format": " {:%H:%M:%S}",
        "format-alt": " {:%A %d %B %Y  %H:%M:%S}",
        "tooltip-format": "<tt><small>{calendar}</small></tt>",
        "calendar": {
            "mode": "month",
            "mode-mon-col": 3,
            "weeks-pos": "right",
            "on-scroll": 1,
            "on-click-right": "mode",
            "format": {
                "months": "<span color='#b3e5fc'><b>{}</b></span>",
                "days": "<span color='#ffffff'><b>{}</b></span>",
                "weeks": "<span color='#4fc3f7'><b>S{}</b></span>",
                "weekdays": "<span color='#80bfff'><b>{}</b></span>",
                "today": "<span color='#4fc3f7'><b><u>{}</u></b></span>"
            }
        }
    },

    "custom/keyboard": {
        "exec": "~/.config/sway/scripts/keyboard-layout.sh",
        "interval": 1,
        "format": "{}",
        "on-click": "~/.config/sway/scripts/toggle-keyboard.sh",
        "tooltip": false
    },

    "custom/cpu": {
        "exec": "~/.config/sway/scripts/cpu.sh",
        "interval": 2,
        "format": "{}",
        "tooltip": false
    },

    "custom/ram": {
        "exec": "~/.config/sway/scripts/ram.sh",
        "interval": 2,
        "format": "{}",
        "tooltip": false
    },

    "custom/ip": {
        "exec": "~/.config/sway/scripts/ip.sh",
        "interval": 10,
        "format": "{}",
        "tooltip": false
    },

    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": "󰝟 Muet",
        "format-icons": {
            "headphone": "",
            "hands-free": "",
            "headset": "",
            "phone": "",
            "portable": "",
            "car": "",
            "default": ["", "", ""]
        },
        "on-click": "pactl set-sink-mute @DEFAULT_SINK@ toggle",
        "on-click-right": "pavucontrol",
        "on-scroll-up": "pactl set-sink-volume @DEFAULT_SINK@ +2%",
        "on-scroll-down": "pactl set-sink-volume @DEFAULT_SINK@ -2%",
        "tooltip-format": "{desc} | {volume}%"
    },

    "network": {
        "format-wifi": "  {essid} ({signalStrength}%)",
        "format-ethernet": "  {ipaddr}/{cidr}",
        "format-disconnected": "󰖪  Déconnecté",
        "tooltip-format": "{ifname}: {ipaddr}/{cidr}\nGateway: {gwaddr}",
        "tooltip-format-wifi": "{essid} ({signalStrength}%)\n {ipaddr}/{cidr}\nGateway: {gwaddr}",
        "on-click": "nm-connection-editor",
        "on-click-right": "nmcli device wifi rescan"
    },

    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{icon} {capacity}%",
        "format-charging": " {capacity}%",
        "format-plugged": " {capacity}%",
        "format-icons": ["", "", "", "", ""],
        "tooltip-format": "{timeTo}, {capacity}%"
    },

    "tray": {
        "icon-size": 18,
        "spacing": 10
    }
}
EOF

cat > "$WAYBAR_DIR/style.css" << 'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free";
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background-color: #00141d;
    color: #ffffff;
}

#workspaces button {
    padding: 0 10px;
    background-color: transparent;
    color: #ffffff;
    border-bottom: 2px solid transparent;
    transition: all 0.3s;
}

#workspaces button:hover {
    background-color: rgba(255, 255, 255, 0.1);
    border-bottom: 2px solid #b3e5fc;
}

#workspaces button.focused,
#workspaces button.active {
    background-color: #4fc3f7;
    color: #00141d;
    border-bottom: 2px solid #b3e5fc;
    font-weight: bold;
}

#mode {
    background-color: #4fc3f7;
    color: #00141d;
    padding: 0 10px;
    margin: 0 5px;
    font-weight: bold;
    border-radius: 5px;
}

#window {
    margin: 0 10px;
    color: #b3e5fc;
    font-style: italic;
}

#clock {
    font-weight: bold;
    color: #b3e5fc;
    padding: 0 15px;
    font-size: 14px;
}

#custom-keyboard,
#custom-cpu,
#custom-ram,
#custom-ip,
#pulseaudio,
#network,
#battery,
#tray {
    padding: 0 10px;
    margin: 0 3px;
    background-color: #1a1a1a;
    border-radius: 5px;
}

#custom-keyboard {
    color: #b3e5fc;
    font-weight: bold;
}

#custom-keyboard:hover {
    background-color: #4fc3f7;
    color: #00141d;
    cursor: pointer;
}

#custom-cpu { color: #4fc3f7; }
#custom-ram { color: #80bfff; }
#custom-ip { color: #b3e5fc; }

#pulseaudio {
    color: #4fc3f7;
}

#pulseaudio:hover {
    background-color: #4fc3f7;
    color: #00141d;
    cursor: pointer;
}

#pulseaudio.muted {
    color: #eb4d4b;
}

#network {
    color: #b3e5fc;
}

#network:hover {
    background-color: #4fc3f7;
    color: #00141d;
    cursor: pointer;
}

#network.disconnected {
    color: #eb4d4b;
}

#battery {
    color: #b3e5fc;
}

#battery.charging,
#battery.plugged {
    color: #26de81;
}

#battery.warning:not(.charging) {
    color: #fed330;
}

#battery.critical:not(.charging) {
    color: #eb4d4b;
    animation: blink 1s linear infinite;
}

@keyframes blink {
    50% { opacity: 0.5; }
}

tooltip {
    background-color: #1a1a1a;
    border: 2px solid #4fc3f7;
    border-radius: 5px;
}
EOF

success "Configuration Waybar créée"

# ========== CONFIGURATION ROFI ==========
msg "Création de la configuration Rofi..."

cat > "$ROFI_DIR/config.rasi" << 'EOF'
configuration {
    modi: "drun,run,window";
    show-icons: true;
    terminal: "foot";
    drun-display-format: "{name}";
    disable-history: false;
    hide-scrollbar: true;
    display-drun: "  Applications";
    display-run: "  Commandes";
    display-window: " 﩯 Fenêtres";
    sidebar-mode: true;
}

@theme "~/.config/sway/rofi/theme.rasi"
EOF

cat > "$ROFI_DIR/theme.rasi" << 'EOF'
* {
    bg: #00141d;
    fg: #FFFFFF;
    cyan: #b3e5fc;
    barbie: #4fc3f7;
    blue: #80bfff;
    gray: #1a1a1a;
    
    background-color: @bg;
    text-color: @fg;
}

window {
    width: 650px;
    padding: 20px;
    border: 2px;
    border-color: @barbie;
    border-radius: 10px;
}

mainbox {
    children: [inputbar, listview, mode-switcher];
    spacing: 15px;
}

inputbar {
    children: [prompt, entry];
    spacing: 10px;
    padding: 12px;
    background-color: @gray;
    border-radius: 6px;
}

prompt {
    text-color: @cyan;
    font: "JetBrainsMono Nerd Font Bold 11";
}

entry {
    placeholder: "Rechercher...";
    placeholder-color: #888888;
}

listview {
    lines: 8;
    spacing: 5px;
    padding: 10px 0;
}

element {
    padding: 10px;
    border-radius: 6px;
    spacing: 10px;
}

element selected {
    background-color: @barbie;
    text-color: @bg;
}

element-icon {
    size: 28px;
}

element-text {
    vertical-align: 0.5;
}

mode-switcher {
    spacing: 10px;
}

button {
    padding: 10px;
    background-color: @gray;
    border-radius: 6px;
}

button selected {
    background-color: @barbie;
    text-color: @bg;
    font: "JetBrainsMono Nerd Font Bold 10";
}
EOF

success "Configuration Rofi créée"

# ============================================================================
# PARTIE 4: VARIABLES D'ENVIRONNEMENT (CORRECTION LAG)
# ============================================================================
section "PARTIE 4/4: Configuration environnement (correction lag)"

msg "Configuration des variables d'environnement..."

cat > "$HOME/.config/environment.d/sway-wayland.conf" << 'EOF'
# Variables pour Wayland et correction lag navigateur

# Force Wayland pour les applications
MOZ_ENABLE_WAYLAND=1
QT_QPA_PLATFORM=wayland
GDK_BACKEND=wayland
CLUTTER_BACKEND=wayland
SDL_VIDEODRIVER=wayland

# Accélération matérielle
WLR_RENDERER=vulkan
WLR_NO_HARDWARE_CURSORS=0

# Support GBM
GBM_BACKEND=mesa

# Mesa
MESA_LOADER_DRIVER_OVERRIDE=iris
EOF

success "Variables d'environnement configurées"

# Firefox Wayland
msg "Configuration de Firefox pour Wayland..."

cat > "$HOME/.local/share/applications/firefox-wayland.desktop" << 'EOF'
[Desktop Entry]
Name=Firefox (Wayland)
GenericName=Web Browser
Comment=Browse the World Wide Web
Exec=env MOZ_ENABLE_WAYLAND=1 firefox %u
Icon=firefox
Terminal=false
Type=Application
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
Categories=Network;WebBrowser;
Keywords=web;browser;internet;
EOF

success "Firefox configuré pour Wayland"

# ============================================================================
# RÉSUMÉ FINAL
# ============================================================================

clear
echo -e "${GREEN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║           ✓ INSTALLATION COMPLÈTE TERMINÉE AVEC SUCCÈS           ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}\n"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}INSTALLATION RÉUSSIE${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo -e "${GREEN}✓${NC} Sway installé et configuré"
echo -e "${GREEN}✓${NC} Waybar avec CPU, RAM, IP, WiFi, Son, Batterie, Langue"
echo -e "${GREEN}✓${NC} Rofi configuré avec thème"
echo -e "${GREEN}✓${NC} Drivers graphiques installés (correction lag)"
echo -e "${GREEN}✓${NC} Résolution 1920x1080 configurée"
echo -e "${GREEN}✓${NC} Raccourcis clavier avec aide (Super+1)"
echo -e "${GREEN}✓${NC} Variables d'environnement Wayland"
echo

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}PROCHAINES ÉTAPES${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo -e "${YELLOW}1.${NC} ${GREEN}Se déconnecter${NC} de votre session actuelle"
echo -e "${YELLOW}2.${NC} ${GREEN}Sélectionner 'Sway'${NC} dans le menu de session (SDDM/GDM/LightDM)"
echo -e "${YELLOW}3.${NC} ${GREEN}Se connecter${NC}"
echo -e "${YELLOW}4.${NC} ${GREEN}Tester${NC} : Appuyer sur ${CYAN}Super + 1${NC} pour voir l'aide complète"
echo

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}RACCOURCIS ESSENTIELS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo -e "  ${CYAN}Super + 1${NC}          Aide complète des raccourcis"
echo -e "  ${CYAN}Super + Espace${NC}     Rofi (lancer applications)"
echo -e "  ${CYAN}Super + Entrée${NC}     Terminal"
echo -e "  ${CYAN}Super + E${NC}          Thunar (fichiers)"
echo -e "  ${CYAN}Super + Q${NC}          Fermer fenêtre"
echo -e "  ${CYAN}Super + Shift + R${NC}  Recharger configuration"
echo

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}WAYBAR - MODULES INTERACTIFS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo -e "  ${CYAN}${NC}  CPU          Consommation processeur"
echo -e "  ${CYAN}${NC}  RAM          Mémoire utilisée"
echo -e "  ${CYAN}${NC}  IP           Adresse IP locale"
echo -e "  ${CYAN}${NC}  WiFi         Signal + clic pour gérer"
echo -e "  ${CYAN}${NC}  Son          Volume (clic=muet, scroll=ajuster)"
echo -e "  ${CYAN}${NC}  Batterie     Niveau batterie"
echo -e "  ${CYAN} FR/EN${NC}       Langue (clic pour changer)"
echo

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}VÉRIFICATION POST-INSTALLATION${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo "Une fois dans Sway, vérifier l'accélération matérielle:"
echo -e "  ${CYAN}\$${NC} glxinfo | grep 'direct rendering'  ${GREEN}# Doit afficher 'Yes'${NC}"
echo -e "  ${CYAN}\$${NC} echo \$MOZ_ENABLE_WAYLAND           ${GREEN}# Doit afficher '1'${NC}"
echo
echo "Dans Firefox (about:support):"
echo -e "  Chercher ${GREEN}'Compositing'${NC} → doit afficher ${GREEN}'WebRender'${NC}"
echo

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Log d'installation sauvegardé:${NC} $LOG_FILE"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo -e "${GREEN}🎉 Profitez de votre nouvel environnement Sway! 🎉${NC}"
echo