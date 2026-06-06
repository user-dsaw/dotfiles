#!/bin/bash

echo "🔥 Ayame's dotfiles bootstrap script"

# Install paru if not present
if ! command -v paru &> /dev/null; then
    echo "Installing paru..."
    sudo pacman -S --needed git base-devel
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    cd /tmp/paru && makepkg -si
    cd -
fi

# Install all packages
echo "Installing packages..."
paru -S --needed \
    hyprland waybar ghostty kitty \
    rofi swaync hyprlock wlogout \
    swww sddm sddm-astronaut-theme \
    zsh stow git lazygit \
    zsh-syntax-highlighting zsh-autosuggestions \
    fzf yazi btop cava \
    fastfetch chafa pokemon-colorscripts-git \
    imagemagick bluetuith bluez bluez-utils \
    ttf-anonymouspro-nerd playerctl \
    grimblast-git nwg-look

# Stow all dotfiles
echo "Stowing dotfiles..."
cd ~/dotfiles
for dir in */; do
    stow "${dir%/}"
done

# Enable services
echo "Enabling services..."
sudo systemctl enable sddm
sudo systemctl enable bluetooth

echo "✅ Done! Reboot and enjoy the rice 🔥"