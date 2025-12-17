#!/bin/bash

# Script de personnalisation Sway + Waybar
# Configure: résolution 1920x1080, waybar avec CPU/RAM/IP/heure, rofi

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

msg() { echo -e "${CYAN}>>> $*${NC}"; }
success() { echo -e "${GREEN}✓ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠ $*${NC}"; }
error() { echo -e "${RED}✗ $*${NC}" >&2; exit 1; }

# Vérifier qu'on n'est pas root
[ "$EUID" -eq 0 ] && error "Ne pas exécuter ce script en root!"

# Chemins
CONFIG_DIR="$HOME/.config/sway"
WAYBAR_DIR="$CONFIG_DIR/waybar"
ROFI_DIR="$CONFIG_DIR/rofi"
SCRIPTS_DIR="$CONFIG_DIR/scripts"

# Banner
clear
echo -e "${CYAN}"
echo "╔════════════════════════════════════════╗"
echo "║   Configuration Sway + Waybar          ║"
echo "║   Personnalisation complète            ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}\n"

# ===== ÉTAPE 1: Créer les répertoires =====
msg "Création des répertoires de configuration..."
mkdir -p "$CONFIG_DIR"
mkdir -p "$WAYBAR_DIR"
mkdir -p "$ROFI_DIR"
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$HOME/Screenshots"
success "Répertoires créés"

# ===== ÉTAPE 2: Configuration de la résolution =====
msg "Configuration de la résolution 1920x1080..."

# Détection des sorties vidéo disponibles
OUTPUTS=$(swaymsg -t get_outputs 2>/dev/null | grep -o '"name":"[^"]*"' | cut -d'"' -f4)

if [ -n "$OUTPUTS" ]; then
    echo "Sorties vidéo détectées:"
    echo "$OUTPUTS"
    echo
    
    # Configuration Sway pour la résolution
    cat > "$CONFIG_DIR/output-config" << 'EOF'
# Configuration de résolution
# Ajustez selon votre sortie vidéo
output * resolution 1920x1080 position 0,0
EOF
    success "Configuration de résolution créée"
else
    warn "Sway n'est pas en cours d'exécution, configuration de résolution créée par défaut"
    cat > "$CONFIG_DIR/output-config" << 'EOF'
# Configuration de résolution
output * resolution 1920x1080 position 0,0
EOF
fi

# ===== ÉTAPE 3: Configuration Sway principale =====
msg "Création de la configuration Sway..."

cat > "$CONFIG_DIR/config" << 'EOF'
# Configuration Sway personnalisée

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
include ~/.config/sway/output-config

# Fond d'écran (couleur unie par défaut)
output * bg #00141d solid_color

### Configuration d'entrée
input type:touchpad {
    dwt enabled
    tap enabled
    natural_scroll enabled
    middle_emulation enabled
}

input type:keyboard {
    xkb_layout "fr"
    xkb_options caps:escape
    repeat_delay 300
    repeat_rate 50
}

### Raccourcis clavier de base
bindsym $mod+Return exec $term
bindsym $mod+q kill
bindsym $mod+space exec $menu
bindsym $mod+Shift+r reload
bindsym $mod+Shift+e exec swaynag -t warning -m 'Quitter Sway?' -B 'Oui' 'swaymsg exit'
bindsym $mod+x exec swaylock -f -c 000000
floating_modifier $mod normal

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

### Espaces de travail
bindsym $mod+1 workspace number 1
bindsym $mod+2 workspace number 2
bindsym $mod+3 workspace number 3
bindsym $mod+4 workspace number 4
bindsym $mod+5 workspace number 5
bindsym $mod+6 workspace number 6
bindsym $mod+7 workspace number 7
bindsym $mod+8 workspace number 8
bindsym $mod+9 workspace number 9
bindsym $mod+0 workspace number 10

bindsym $mod+Shift+1 move container to workspace number 1
bindsym $mod+Shift+2 move container to workspace number 2
bindsym $mod+Shift+3 move container to workspace number 3
bindsym $mod+Shift+4 move container to workspace number 4
bindsym $mod+Shift+5 move container to workspace number 5
bindsym $mod+Shift+6 move container to workspace number 6
bindsym $mod+Shift+7 move container to workspace number 7
bindsym $mod+Shift+8 move container to workspace number 8
bindsym $mod+Shift+9 move container to workspace number 9
bindsym $mod+Shift+0 move container to workspace number 10

### Disposition
bindsym $mod+b splith
bindsym $mod+v splitv
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split
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
bindsym Print exec grim ~/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
bindsym $mod+Print exec grim -g "$(slurp)" ~/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
bindsym Shift+Print exec grim -g "$(slurp)" - | wl-copy

### Contrôles média
bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle
bindsym XF86MonBrightnessUp exec brightnessctl set +5%
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-

### Apparence
font pango:JetBrainsMono Nerd Font 10
default_border pixel 2
default_floating_border pixel 2
gaps inner 10
gaps outer 5

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
exec waybar -c ~/.config/sway/waybar/config -s ~/.config/sway/waybar/style.css
exec mako
exec wl-paste --watch cliphist store

# Import des variables d'environnement
exec systemctl --user import-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK
exec dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK
EOF

success "Configuration Sway créée"

# ===== ÉTAPE 4: Installation de Rofi =====
msg "Vérification de Rofi..."
if ! command -v rofi &> /dev/null; then
    warn "Rofi n'est pas installé. Installation..."
    sudo apt-get update
    sudo apt-get install -y rofi
    success "Rofi installé"
else
    success "Rofi déjà installé"
fi

# ===== ÉTAPE 5: Configuration Rofi =====
msg "Configuration de Rofi..."

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
    
    background-color: @bg;
    text-color: @fg;
}

window {
    width: 600px;
    padding: 20px;
    border: 2px;
    border-color: @barbie;
    border-radius: 8px;
}

mainbox {
    children: [inputbar, listview, mode-switcher];
    spacing: 10px;
}

inputbar {
    children: [prompt, entry];
    spacing: 10px;
    padding: 10px;
    background-color: #1a1a1a;
    border-radius: 5px;
}

prompt {
    text-color: @cyan;
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
    padding: 8px;
    border-radius: 5px;
}

element selected {
    background-color: @barbie;
    text-color: @bg;
}

element-icon {
    size: 24px;
    margin: 0 10px 0 0;
}

mode-switcher {
    spacing: 10px;
}

button {
    padding: 8px;
    background-color: #1a1a1a;
    border-radius: 5px;
}

button selected {
    background-color: @barbie;
    text-color: @bg;
}
EOF

success "Configuration Rofi créée"

# ===== ÉTAPE 6: Scripts pour Waybar =====
msg "Création des scripts pour Waybar..."

# Script CPU
cat > "$SCRIPTS_DIR/cpu.sh" << 'EOF'
#!/bin/bash
cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
printf "%.0f%%" "$cpu_usage"
EOF
chmod +x "$SCRIPTS_DIR/cpu.sh"

# Script RAM
cat > "$SCRIPTS_DIR/ram.sh" << 'EOF'
#!/bin/bash
mem_info=$(free -m | awk 'NR==2{printf "%.0f%%", $3*100/$2}')
echo "$mem_info"
EOF
chmod +x "$SCRIPTS_DIR/ram.sh"

# Script IP
cat > "$SCRIPTS_DIR/ip.sh" << 'EOF'
#!/bin/bash
# Obtenir l'IP locale (première interface active)
ip_addr=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
if [ -z "$ip_addr" ]; then
    echo "Pas d'IP"
else
    echo "$ip_addr"
fi
EOF
chmod +x "$SCRIPTS_DIR/ip.sh"

success "Scripts créés"

# ===== ÉTAPE 7: Configuration Waybar =====
msg "Configuration de Waybar..."

cat > "$WAYBAR_DIR/config" << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 35,
    "spacing": 5,
    
    "modules-left": ["sway/workspaces", "sway/mode"],
    "modules-center": ["clock"],
    "modules-right": ["custom/ip", "custom/cpu", "custom/ram", "pulseaudio", "network", "battery", "tray"],

    "sway/workspaces": {
        "disable-scroll": false,
        "all-outputs": true,
        "format": "{name}",
        "persistent_workspaces": {
            "1": [],
            "2": [],
            "3": [],
            "4": [],
            "5": []
        }
    },

    "sway/mode": {
        "format": "<span style=\"italic\"> {}</span>"
    },

    "clock": {
        "interval": 1,
        "format": "{:%H:%M:%S}",
        "format-alt": "{:%A %d %B %Y  %H:%M:%S}",
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

    "custom/cpu": {
        "exec": "~/.config/sway/scripts/cpu.sh",
        "interval": 2,
        "format": " {}",
        "tooltip": false
    },

    "custom/ram": {
        "exec": "~/.config/sway/scripts/ram.sh",
        "interval": 2,
        "format": " {}",
        "tooltip": false
    },

    "custom/ip": {
        "exec": "~/.config/sway/scripts/ip.sh",
        "interval": 10,
        "format": "  {}",
        "tooltip": false
    },

    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": "󰝟 Muet",
        "format-icons": {
            "default": ["", "", ""]
        },
        "on-click": "pactl set-sink-mute @DEFAULT_SINK@ toggle",
        "on-click-right": "pavucontrol",
        "tooltip": false
    },

    "network": {
        "format-wifi": "  {essid}",
        "format-ethernet": "  Connecté",
        "format-disconnected": "󰖪  Déconnecté",
        "tooltip-format": "{ifname}: {ipaddr}/{cidr}",
        "on-click": "nm-connection-editor"
    },

    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{icon} {capacity}%",
        "format-charging": " {capacity}%",
        "format-plugged": " {capacity}%",
        "format-icons": ["", "", "", "", ""]
    },

    "tray": {
        "icon-size": 18,
        "spacing": 10
    }
}
EOF

success "Configuration Waybar créée"

# ===== ÉTAPE 8: Style Waybar =====
msg "Création du style Waybar..."

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
    transition-property: background-color;
    transition-duration: 0.5s;
}

window#waybar.hidden {
    opacity: 0.2;
}

#workspaces {
    margin: 0 5px;
}

#workspaces button {
    padding: 0 8px;
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
}

#workspaces button.urgent {
    background-color: #eb4d4b;
}

#mode {
    background-color: #4fc3f7;
    color: #00141d;
    padding: 0 10px;
    margin: 0 5px;
    font-weight: bold;
}

#clock {
    font-weight: bold;
    color: #b3e5fc;
    padding: 0 15px;
}

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

#custom-cpu {
    color: #4fc3f7;
}

#custom-ram {
    color: #80bfff;
}

#custom-ip {
    color: #b3e5fc;
}

#pulseaudio {
    color: #4fc3f7;
}

#pulseaudio.muted {
    color: #eb4d4b;
}

#network {
    color: #b3e5fc;
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
}

#tray {
    background-color: #1a1a1a;
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
    background-color: #eb4d4b;
}

tooltip {
    background-color: #1a1a1a;
    border: 2px solid #4fc3f7;
    border-radius: 5px;
}

tooltip label {
    color: #ffffff;
}
EOF

success "Style Waybar créé"

# ===== ÉTAPE 9: Vérification des dépendances =====
msg "Vérification des dépendances..."

MISSING_DEPS=()

for cmd in foot grim slurp wl-copy pactl brightnessctl mako cliphist; do
    if ! command -v $cmd &> /dev/null; then
        MISSING_DEPS+=($cmd)
    fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    warn "Dépendances manquantes: ${MISSING_DEPS[*]}"
    read -p "Voulez-vous les installer? (o/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[OoYy]$ ]]; then
        msg "Installation des dépendances..."
        
        # Conversion des noms de commandes en paquets
        PACKAGES=()
        for dep in "${MISSING_DEPS[@]}"; do
            case $dep in
                "wl-copy") PACKAGES+=("wl-clipboard");;
                "pactl") PACKAGES+=("pulseaudio-utils");;
                *) PACKAGES+=("$dep");;
            esac
        done
        
        sudo apt-get update
        sudo apt-get install -y "${PACKAGES[@]}"
        success "Dépendances installées"
    fi
else
    success "Toutes les dépendances sont présentes"
fi

# ===== ÉTAPE 10: Résumé et instructions =====
clear
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║          Configuration terminée avec succès! ✓             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

echo -e "${CYAN}Configurations créées:${NC}"
echo "  • Sway config: $CONFIG_DIR/config"
echo "  • Waybar config: $WAYBAR_DIR/config"
echo "  • Waybar style: $WAYBAR_DIR/style.css"
echo "  • Rofi config: $ROFI_DIR/config.rasi"
echo "  • Scripts: $SCRIPTS_DIR/"
echo

echo -e "${CYAN}Fonctionnalités configurées:${NC}"
echo "  ✓ Résolution: 1920x1080"
echo "  ✓ Waybar avec CPU, RAM, IP, Heure"
echo "  ✓ Rofi pour lancer les applications"
echo "  ✓ Raccourcis clavier optimisés"
echo "  ✓ Thème cohérent (bleu cyan)"
echo

echo -e "${YELLOW}Raccourcis clavier importants:${NC}"
echo "  • Super + Espace      → Rofi (lancer applications)"
echo "  • Super + Entrée      → Terminal"
echo "  • Super + Q           → Fermer fenêtre"
echo "  • Super + Shift + R   → Recharger configuration"
echo "  • Super + Shift + E   → Quitter Sway"
echo "  • Print               → Capture d'écran"
echo

echo -e "${CYAN}Pour appliquer les changements:${NC}"
echo "  1. Recharger Sway: Super + Shift + R"
echo "  2. Ou redémarrer Sway complètement"
echo

echo -e "${GREEN}Configuration terminée!${NC}"
echo