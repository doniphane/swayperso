#!/bin/bash

# Script de personnalisation Sway + Waybar - VERSION COMPLÈTE
# Toutes les fonctionnalités: icônes, wifi, son, aide, changement langue, etc.

set -e

# Couleurs
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
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Configuration Sway + Waybar ULTRA COMPLÈTE            ║"
echo "║     Avec icônes, wifi, son, aide, changement langue       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

# Créer les répertoires
msg "Création des répertoires..."
mkdir -p "$CONFIG_DIR"
mkdir -p "$WAYBAR_DIR"
mkdir -p "$ROFI_DIR"
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$HOME/Screenshots"
success "Répertoires créés"

# ===== SCRIPTS POUR WAYBAR =====
msg "Création des scripts pour Waybar..."

# Script CPU avec icône
cat > "$SCRIPTS_DIR/cpu.sh" << 'EOF'
#!/bin/bash
cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
printf " %.0f%%" "$cpu_usage"
EOF
chmod +x "$SCRIPTS_DIR/cpu.sh"

# Script RAM avec icône
cat > "$SCRIPTS_DIR/ram.sh" << 'EOF'
#!/bin/bash
mem_info=$(free -m | awk 'NR==2{printf " %.0f%%", $3*100/$2}')
echo "$mem_info"
EOF
chmod +x "$SCRIPTS_DIR/ram.sh"

# Script IP avec icône
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

# Script changement de langue clavier
cat > "$SCRIPTS_DIR/keyboard-layout.sh" << 'EOF'
#!/bin/bash
# Obtenir la disposition actuelle
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

# Script pour changer la langue
cat > "$SCRIPTS_DIR/toggle-keyboard.sh" << 'EOF'
#!/bin/bash
# Basculer entre FR et US
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

# Script d'aide (raccourcis clavier)
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
" -theme ~/.config/sway/rofi/theme.rasi
EOF
chmod +x "$SCRIPTS_DIR/help.sh"

success "Scripts créés"

# ===== CONFIGURATION SWAY =====
msg "Création de la configuration Sway complète..."

cat > "$CONFIG_DIR/config" << 'EOF'
# Configuration Sway ultra-personnalisée

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

# NOUVEAU: Aide (Super+1)
bindsym $mod+1 exec $config_dir/scripts/help.sh

# NOUVEAU: Thunar (Super+E)
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

### Espaces de travail (2 par défaut, extensible)
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

### Contrôles multimédia et volume
bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5% && notify-send "Volume" "$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+(?=%)' | head -n1)%" -t 1000
bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5% && notify-send "Volume" "$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+(?=%)' | head -n1)%" -t 1000
bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle && notify-send "Volume" "Muet basculé" -t 1000
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

# Import des variables d'environnement
exec systemctl --user import-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK
exec dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK

### Règles pour fenêtres flottantes
for_window [app_id="pavucontrol"] floating enable
for_window [app_id="nm-connection-editor"] floating enable
for_window [title="Aide - Raccourcis"] floating enable
EOF

success "Configuration Sway créée"

# ===== CONFIGURATION WAYBAR COMPLÈTE =====
msg "Configuration de Waybar avec tous les modules..."

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

success "Configuration Waybar créée"

# ===== STYLE WAYBAR =====
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

#workspaces button.urgent {
    background-color: #eb4d4b;
    animation: blink 1s linear infinite;
}

@keyframes blink {
    50% { opacity: 0.5; }
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

#custom-keyboard {
    padding: 0 10px;
    margin: 0 3px;
    background-color: #1a1a1a;
    border-radius: 5px;
    color: #b3e5fc;
    font-weight: bold;
}

#custom-keyboard:hover {
    background-color: #4fc3f7;
    color: #00141d;
    cursor: pointer;
}

#custom-cpu {
    padding: 0 10px;
    margin: 0 3px;
    background-color: #1a1a1a;
    border-radius: 5px;
    color: #4fc3f7;
}

#custom-ram {
    padding: 0 10px;
    margin: 0 3px;
    background-color: #1a1a1a;
    border-radius: 5px;
    color: #80bfff;
}

#custom-ip {
    padding: 0 10px;
    margin: 0 3px;
    background-color: #1a1a1a;
    border-radius: 5px;
    color: #b3e5fc;
}

#pulseaudio {
    padding: 0 10px;
    margin: 0 3px;
    background-color: #1a1a1a;
    border-radius: 5px;
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
    padding: 0 10px;
    margin: 0 3px;
    background-color: #1a1a1a;
    border-radius: 5px;
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
    padding: 0 10px;
    margin: 0 3px;
    background-color: #1a1a1a;
    border-radius: 5px;
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

#tray {
    padding: 0 5px;
    background-color: #1a1a1a;
    border-radius: 5px;
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

# ===== CONFIGURATION ROFI =====
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

# ===== VÉRIFICATION DES DÉPENDANCES =====
msg "Vérification des dépendances..."

MISSING_DEPS=()
REQUIRED_PACKAGES=(
    "foot" 
    "grim" 
    "slurp" 
    "wl-clipboard:wl-copy"
    "pulseaudio-utils:pactl"
    "brightnessctl"
    "mako"
    "cliphist"
    "rofi"
    "thunar"
    "network-manager"
    "pavucontrol"
    "jq"
    "playerctl"
    "nm-applet:nm-applet"
    "swaylock"
)

for pkg in "${REQUIRED_PACKAGES[@]}"; do
    cmd="${pkg##*:}"
    [ "$cmd" = "$pkg" ] && pkg_name="$pkg" || pkg_name="${pkg%%:*}"
    
    if ! command -v "$cmd" &> /dev/null; then
        MISSING_DEPS+=("$pkg_name")
    fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    warn "Dépendances manquantes: ${MISSING_DEPS[*]}"
    read -p "Installer les dépendances manquantes? (o/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[OoYy]$ ]]; then
        msg "Installation des dépendances..."
        sudo apt-get update
        sudo apt-get install -y "${MISSING_DEPS[@]}"
        success "Dépendances installées"
    fi
else
    success "Toutes les dépendances sont présentes"
fi

# ===== RÉSUMÉ FINAL =====
clear
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║       Configuration ULTRA-COMPLÈTE terminée avec succès! ✓    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}FONCTIONNALITÉS CONFIGURÉES${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo -e "${CYAN}Waybar (barre supérieure)${NC}"
echo "  ✓ Module CPU avec icône "
echo "  ✓ Module RAM avec icône "
echo "  ✓ Module IP avec icône "
echo "  ✓ Module WiFi/Réseau avec icône  (clic pour gérer)"
echo "  ✓ Module Son avec icône  (clic pour muet, scroll pour volume)"
echo "  ✓ Module Batterie avec icône "
echo "  ✓ Module Langue clavier  FR/EN (clic pour changer)"
echo "  ✓ Horloge complète avec calendrier "
echo "  ✓ 2 bureaux configurés par défaut"
echo
echo -e "${CYAN}Applications et raccourcis${NC}"
echo "  ✓ Rofi pour lancer les applications"
echo "  ✓ Aide complète des raccourcis (Super+1)"
echo "  ✓ Thunar (gestionnaire de fichiers) Super+E"
echo "  ✓ Notifications avec mako"
echo "  ✓ Captures d'écran configurées"
echo
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}RACCOURCIS CLAVIER ESSENTIELS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo -e "${GREEN}Applications${NC}"
echo "  Super + Espace       Rofi (lancer applications)"
echo "  Super + Entrée       Terminal"
echo "  Super + E            Thunar (fichiers)"
echo "  Super + 1            Aide complète"
echo
echo -e "${GREEN}Gestion fenêtres${NC}"
echo "  Super + Q            Fermer fenêtre"
echo "  Super + F            Plein écran"
echo "  Super + H/J/K/L      Naviguer"
echo
echo -e "${GREEN}Système${NC}"
echo "  Super + Shift + R    Recharger config"
echo "  Super + Shift + E    Quitter Sway"
echo "  Super + X            Verrouiller"
echo "  Print                Screenshot"
echo
echo -e "${GREEN}Waybar (interactions)${NC}"
echo "  Clic sur           Changer langue clavier"
echo "  Clic sur         Muet/démuet"
echo "  Scroll sur       Ajuster volume"
echo "  Clic sur         Gérer WiFi"
echo "  Clic droit sur   Scanner réseaux"
echo
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}POUR APPLIQUER LES CHANGEMENTS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo "  1. Si vous êtes dans Sway: Super + Shift + R"
echo "  2. Sinon: Se déconnecter et se reconnecter"
echo "  3. Tester: Super + 1 pour l'aide complète"
echo
echo -e "${GREEN}Configuration terminée avec succès! 🎉${NC}"
echo