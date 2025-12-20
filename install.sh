#!/bin/bash
# ==========================================
# SCRIPT DE INSTALACIÓN (herwingx)
# ==========================================

# --- 1. DETECCIÓN DE PERMISOS (ROOT vs USER) ---
if [ "$(id -u)" -eq 0 ]; then
    echo ">>> Ejecutando como ROOT (Modo LXC detectado)"
    SUDO_CMD=""
else
    echo ">>> Ejecutando como USUARIO (Modo VM detectado)"
    SUDO_CMD="sudo"
fi

# --- 2. PAQUETES A INSTALAR ---
PACKAGES=(
    "git" "curl" "wget" "htop" "vim" "unzip" "neofetch" "dnsutils"
)

GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}>>> Iniciando configuración para herwingx...${NC}"

# --- 3. INSTALACIÓN DE SISTEMA ---
if [ -f /etc/debian_version ]; then
    $SUDO_CMD apt-get update -y
    $SUDO_CMD apt-get install -y "${PACKAGES[@]}"
elif [ -f /etc/redhat-release ]; then
    $SUDO_CMD dnf install -y "${PACKAGES[@]}"
fi

# --- 4. ALIAS (Symlink) ---
echo -e "${GREEN}>>> Vinculando Bash Aliases...${NC}"
DOTFILES_DIR=$(pwd)
ALIAS_FILE="$HOME/.bash_aliases"
[ -f "$ALIAS_FILE" ] && [ ! -L "$ALIAS_FILE" ] && mv "$ALIAS_FILE" "$ALIAS_FILE.backup"
ln -sf "$DOTFILES_DIR/.bash_aliases" "$ALIAS_FILE"

# --- 5. GIT (Config + SSH Hack) ---
echo -e "${GREEN}>>> Configurando Git...${NC}"
cp "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
# Fuerza el uso de SSH aunque copies links HTTPS (Vital para forwarding)
git config --global url."git@github.com:".insteadOf "[https://github.com/](https://github.com/)"

# --- 6. AUTORIZAR LLAVES SSH (Sincronización con GitHub) ---
echo -e "${GREEN}>>> Importando llaves públicas de herwingx...${NC}"
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
# Descarga tus llaves oficiales y las agrega al servidor
curl -s "[https://github.com/herwingx.keys](https://github.com/herwingx.keys)" >> "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"

# --- 7. FINALIZAR ---
echo -e "${GREEN}>>> ¡INSTALACIÓN COMPLETADA!${NC}"
neofetch