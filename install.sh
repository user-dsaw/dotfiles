#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
GOLD='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

# Icons
OK="${GREEN}[✓]${NC}"
FAIL="${RED}[✗]${NC}"
INFO="${GOLD}[~]${NC}"
WARN="${YELLOW}[!]${NC}"

# Welcome screen
clear
echo -e "${GOLD}"
cat << 'EOF'
    ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
    ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
    ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
    ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
    ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
    ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
EOF
echo -e "${NC}"
echo -e "${BOLD}         Ayame's Hyprland Rice — github.com/user-dsaw/dotfiles${NC}"
echo ""
echo -e "${GOLD}  ┌─────────────────────────────────────────────────────────┐${NC}"
echo -e "${GOLD}  │  ${NC}Built for ${BOLD}performance${NC}, not flash.                        ${GOLD}│${NC}"
echo -e "${GOLD}  │  ${NC}No bloat. No unnecessary animations. Just a clean,     ${GOLD}│${NC}"
echo -e "${GOLD}  │  ${NC}fast, and minimal Hyprland workflow that gets out       ${GOLD}│${NC}"
echo -e "${GOLD}  │  ${NC}of your way.                                            ${GOLD}│${NC}"
echo -e "${GOLD}  └─────────────────────────────────────────────────────────┘${NC}"
echo ""

# Check if Arch
if [ ! -f /etc/arch-release ]; then
    echo -e "${FAIL} This script is for Arch Linux only."
    exit 1
fi
echo -e "${OK} Arch Linux detected"

# Check if paru
if ! command -v paru &> /dev/null; then
    echo -e "${WARN} paru not found. Installing..."
    sudo pacman -S --needed git base-devel
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    cd /tmp/paru && makepkg -si
    cd -
else
    echo -e "${OK} paru found"
fi

echo ""
echo -e "${GOLD}┌─────────────────────────────┐${NC}"
echo -e "${GOLD}│      INSTALLATION OPTIONS    │${NC}"
echo -e "${GOLD}└─────────────────────────────┘${NC}"
echo ""

# Prompts
read -p "$(echo -e ${GOLD}[?]${NC}) Install all packages? [y/N] " install_packages
read -p "$(echo -e ${GOLD}[?]${NC}) Stow dotfiles? [y/N] " stow_dotfiles
read -p "$(echo -e ${GOLD}[?]${NC}) Enable services (sddm, bluetooth)? [y/N] " enable_services

echo ""
echo -e "${INFO} Starting installation..."
echo ""

# Packages
if [[ "$install_packages" =~ ^[Yy]$ ]]; then
    packages=(
        hyprland waybar ghostty kitty
        rofi swaync hyprlock wlogout
        swww sddm sddm-astronaut-theme
        zsh stow git lazygit
        zsh-syntax-highlighting zsh-autosuggestions
        fzf yazi btop cava
        fastfetch chafa pokemon-colorscripts-git
        imagemagick bluetuith bluez bluez-utils
        ttf-anonymouspro-nerd playerctl
        grimblast-git nwg-look
    )

    for pkg in "${packages[@]}"; do
        if paru -S --needed --noconfirm "$pkg" &>/dev/null; then
            echo -e "${OK} $pkg"
        else
            echo -e "${FAIL} $pkg"
        fi
    done
fi

# Stow
if [[ "$stow_dotfiles" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${INFO} Stowing dotfiles..."
    cd ~/dotfiles
    for dir in */; do
        pkg="${dir%/}"
        if stow "$pkg" 2>/dev/null; then
            echo -e "${OK} stowed $pkg"
        else
            stow --adopt "$pkg" 2>/dev/null
            echo -e "${WARN} adopted $pkg"
        fi
    done
fi

# Services
if [[ "$enable_services" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${INFO} Enabling services..."
    sudo systemctl enable sddm && echo -e "${OK} sddm enabled"
    sudo systemctl enable bluetooth && echo -e "${OK} bluetooth enabled"
fi

# Post install
echo ""
echo -e "${GOLD}"
cat << 'EOF'
  ┌──────────────────────────────────────────────────────────┐
  │                    KEYBINDS CHEATSHEET                    │
  ├──────────────────────────────────────────────────────────┤
  │  SUPER + Return       Open terminal (ghostty)            │
  │  SUPER + D            App launcher (rofi)                │
  │  SUPER + Q            Close window                       │
  │  SUPER + E            File manager (yazi)                │
  │  SUPER + L            Lock screen (hyprlock)             │
  │  SUPER + SHIFT + E    Power menu                         │
  │  SUPER + 1-5          Switch workspace                   │
  │  SUPER + SHIFT + 1-5  Move window to workspace           │
  │  SUPER + H/J/K/L      Move focus                         │
  └──────────────────────────────────────────────────────────┘
EOF
echo -e "${NC}"
echo -e "${GREEN}${BOLD}  ✓ All done! Reboot to apply everything.${NC}"
echo -e "${GOLD}  github.com/user-dsaw/dotfiles${NC}"
echo ""