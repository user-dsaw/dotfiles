#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────
#  DOTFILES INSTALLER
#  github.com/user-dsaw/dotfiles
# ─────────────────────────────────────────────

# ── Colors & icons ───────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
GOLD='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

OK="${GREEN}[✓]${NC}"
FAIL="${RED}[✗]${NC}"
INFO="${GOLD}[~]${NC}"
WARN="${YELLOW}[!]${NC}"

# ── Resolve runtime context ───────────────────
# DOTFILES_DIR is always the directory this script lives in.
# This means: clone anywhere, it still works.
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_USER="${USER}"
TARGET_HOME="${HOME}"

# ── Helper functions ──────────────────────────
log_ok()   { echo -e "${OK} $*"; }
log_fail() { echo -e "${FAIL} $*"; }
log_info() { echo -e "${INFO} $*"; }
log_warn() { echo -e "${WARN} $*"; }

# Backs up a file/dir if it exists and is NOT already a symlink
backup_if_exists() {
    local target="$1"
    if [[ -e "$target" && ! -L "$target" ]]; then
        local backup="${target}.bak.$(date +%s)"
        mv "$target" "$backup"
        log_warn "backed up existing $(basename "$target") → $backup"
    fi
}

# Stows a package safely:
# - backs up conflicting real files first
# - never uses --adopt (which would overwrite repo files)
stow_package() {
    local pkg="$1"
    local pkg_path="$DOTFILES_DIR/$pkg"

    if [[ ! -d "$pkg_path" ]]; then
        log_warn "skipping $pkg (directory not found)"
        return
    fi

    # Find what stow would create and back up conflicts
    while IFS= read -r -d '' file; do
        local rel="${file#$pkg_path/}"
        local dest="$TARGET_HOME/$rel"
        backup_if_exists "$dest"
    done < <(find "$pkg_path" -type f -print0)

    if stow --dir="$DOTFILES_DIR" --target="$TARGET_HOME" "$pkg" 2>/dev/null; then
        log_ok "stowed $pkg"
    else
        log_fail "stow failed for $pkg"
    fi
}

# ── Banner ────────────────────────────────────
print_banner() {
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
    echo -e "${BOLD}         Hyprland Dotfiles — github.com/user-dsaw/dotfiles${NC}"
    echo -e "${GOLD}         Installing for: ${BOLD}${TARGET_USER}${NC} → ${BOLD}${TARGET_HOME}${NC}"
    echo ""
}

# ─────────────────────────────────────────────
#  PHASE 1 — PREFLIGHT CHECKS
# ─────────────────────────────────────────────
preflight() {
    echo -e "${GOLD}── Preflight ──────────────────────────────────${NC}"

    # Must be Arch
    if [[ ! -f /etc/arch-release ]]; then
        log_fail "This installer is for Arch Linux only."
        exit 1
    fi
    log_ok "Arch Linux detected"

    # Must not run as root
    if [[ "$EUID" -eq 0 ]]; then
        log_fail "Do not run this as root. Run as your normal user."
        exit 1
    fi
    log_ok "running as non-root user ($TARGET_USER)"

    # stow must be present (it's our core tool)
    if ! command -v stow &>/dev/null; then
        log_info "stow not found — installing..."
        sudo pacman -S --needed --noconfirm stow
    fi
    log_ok "stow available"

    echo ""
}

# ─────────────────────────────────────────────
#  PHASE 2 — PACKAGE INSTALLATION
# ─────────────────────────────────────────────

# Ensures paru is available
ensure_paru() {
    if command -v paru &>/dev/null; then
        log_ok "paru found"
        return
    fi
    log_info "paru not found — installing..."
    sudo pacman -S --needed --noconfirm git base-devel
    local tmp
    tmp="$(mktemp -d)"
    git clone https://aur.archlinux.org/paru.git "$tmp/paru"
    (cd "$tmp/paru" && makepkg -si --noconfirm)
    rm -rf "$tmp"
    log_ok "paru installed"
}

install_packages() {
    echo -e "${GOLD}── Packages ────────────────────────────────────${NC}"
    ensure_paru

    # Core Hyprland environment
    local packages=(
        hyprland
        waybar
        ghostty
        kitty
        rofi
        swaync
        hyprlock
        wlogout
        swww
        zsh
        stow
        git
        lazygit
        zsh-syntax-highlighting
        zsh-autosuggestions
        fzf
        yazi
        btop
        cava
        fastfetch
        chafa
        pokemon-colorscripts-git
        imagemagick
        bluetuith
        bluez
        bluez-utils
        ttf-anonymouspro-nerd
        playerctl
        grimblast-git
        nwg-look
    )

    local failed=()
    for pkg in "${packages[@]}"; do
        if paru -S --needed --noconfirm "$pkg" &>/dev/null; then
            log_ok "$pkg"
        else
            log_fail "$pkg"
            failed+=("$pkg")
        fi
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        echo ""
        log_warn "the following packages failed to install:"
        for pkg in "${failed[@]}"; do
            echo "        - $pkg"
        done
        log_warn "you can install them manually with: paru -S ${failed[*]}"
    fi

    echo ""
}

# ─────────────────────────────────────────────
#  PHASE 3 — SHELL SETUP (oh-my-zsh + p10k)
# ─────────────────────────────────────────────
install_shell() {
    echo -e "${GOLD}── Shell setup ─────────────────────────────────${NC}"

    # Oh My Zsh
    if [[ -d "$TARGET_HOME/.oh-my-zsh" ]]; then
        log_ok "oh-my-zsh already installed"
    else
        log_info "installing oh-my-zsh..."
        RUNZSH=no CHSH=no \
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        log_ok "oh-my-zsh installed"
    fi

    # Powerlevel10k theme
    local p10k_dir="${ZSH_CUSTOM:-$TARGET_HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [[ -d "$p10k_dir" ]]; then
        log_ok "powerlevel10k already installed"
    else
        log_info "installing powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
        log_ok "powerlevel10k installed"
    fi

    # Set zsh as default shell if it isn't already
    if [[ "$SHELL" != "$(command -v zsh)" ]]; then
        log_info "setting zsh as default shell..."
        chsh -s "$(command -v zsh)" "$TARGET_USER"
        log_ok "default shell set to zsh (takes effect on next login)"
    else
        log_ok "zsh is already the default shell"
    fi

    echo ""
}

# ─────────────────────────────────────────────
#  PHASE 4 — STOW DOTFILES
# ─────────────────────────────────────────────
stow_dotfiles() {
    echo -e "${GOLD}── Stowing dotfiles ────────────────────────────${NC}"

    # oh-my-zsh installs its own .zshrc — remove it before stowing ours
    if [[ -f "$TARGET_HOME/.zshrc" && ! -L "$TARGET_HOME/.zshrc" ]]; then
        local backup="$TARGET_HOME/.zshrc.bak.$(date +%s)"
        mv "$TARGET_HOME/.zshrc" "$backup"
        log_warn "moved oh-my-zsh default .zshrc → $backup"
    fi

    local packages=(
        btop
        cava
        fastfetch
        ghostty
        gtk
        hypr
        kitty
        lazygit
        rofi
        swaync
        waybar
        wlogout
        yazi
        zsh
        themes
    )

    for pkg in "${packages[@]}"; do
        stow_package "$pkg"
    done

    # Hyprland v0.55+ overwrites hyprland.conf on first launch for users that are installing / cloning a new dotfile 
    # even through symlinks into the stow repo. Make it read-only to prevent this.
    local hypr_conf="$TARGET_HOME/.config/hypr/hyprland.conf"
    if [[ -L "$TARGET_HOME/.config/hypr" && -f "$hypr_conf" ]]; then
        chmod 444 "$hypr_conf"
        log_ok "hyprland.conf protected from overwrite (chmod 444)"
    fi

    echo ""
}

# ─────────────────────────────────────────────
#  PHASE 5 — SERVICES
# ─────────────────────────────────────────────
enable_services() {
    echo -e "${GOLD}── Services ────────────────────────────────────${NC}"

    # Only enable bluetooth — we do NOT touch display manager
    # to avoid conflicting with whatever the user already has
    if systemctl list-unit-files bluetooth.service &>/dev/null; then
        sudo systemctl enable --now bluetooth
        log_ok "bluetooth enabled"
    else
        log_warn "bluetooth service not found — skipping"
    fi

    echo ""
}

# ─────────────────────────────────────────────
#  PHASE 6 — POST-INSTALL SUMMARY
# ─────────────────────────────────────────────
print_summary() {
    echo -e "${GOLD}"
    cat << 'EOF'
  ┌──────────────────────────────────────────────────────────┐
  │                    KEYBINDS CHEATSHEET                   │
  ├──────────────────────────────────────────────────────────┤
  │  SUPER + Return       Open terminal (ghostty)            │
  │  SUPER + D            App launcher (rofi)                │
  │  SUPER + Q            Close window                       │
  │  SUPER + E            File manager (yazi)                │
  │  SUPER + L            Lock screen (hyprlock)             │
  │  SUPER + SHIFT + E    Power menu (wlogout)               │
  │  SUPER + 1-5          Switch workspace                   │
  │  SUPER + SHIFT + 1-5  Move window to workspace           │
  │  SUPER + H/J/K/L      Move focus                         │
  └──────────────────────────────────────────────────────────┘
EOF
    echo -e "${NC}"
    echo -e "${GREEN}${BOLD}  ✓ Done. Log out and back in (or reboot) to apply all changes.${NC}"
    echo -e "${GOLD}  github.com/user-dsaw/dotfiles${NC}"
    echo ""
}

# ─────────────────────────────────────────────
#  ENTRY POINT
# ─────────────────────────────────────────────
print_banner
preflight

# Default: run everything
# Future: add argument parsing here for profiles (base/hyprland/full)
install_packages
install_shell
stow_dotfiles
enable_services
print_summary
