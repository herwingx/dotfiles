#!/bin/bash
# ==========================================
# SYSTEM - Actualización y paquetes del sistema
# ==========================================
# Funciones para actualizar el sistema operativo e instalar
# paquetes base y herramientas avanzadas de terminal.
# Soporta: Debian/Ubuntu, Fedora/RHEL, Arch Linux
# ==========================================

# ─────────────────────────────────────────────────────────────
# Actualiza el sistema operativo según la distribución detectada.
# Ejecuta upgrade y autoremove para limpiar paquetes huérfanos.
# ─────────────────────────────────────────────────────────────
update_system() {
    echo -e "${GREEN}>>> Actualizando el sistema...${NC}"
    
    if [ -f /etc/debian_version ]; then
        echo -e "${CYAN}   Detectado: Debian/Ubuntu (apt)${NC}"
        $SUDO_CMD apt-get update -y
        $SUDO_CMD apt-get upgrade -y
        $SUDO_CMD apt-get autoremove -y
    elif [ -f /etc/redhat-release ]; then
        echo -e "${CYAN}   Detectado: Fedora/RHEL (dnf)${NC}"
        $SUDO_CMD dnf upgrade --refresh -y
        $SUDO_CMD dnf autoremove -y
    elif [ -f /etc/arch-release ]; then
        echo -e "${CYAN}   Detectado: Arch Linux (pacman)${NC}"
        $SUDO_CMD pacman -Syu --noconfirm
    else
        echo -e "${RED}>>> Sistema no soportado para actualización automática${NC}"
        return
    fi
    
    echo -e "${CYAN}   ✓ Sistema actualizado${NC}"
}

# ─────────────────────────────────────────────────────────────
# Instala paquetes esenciales del sistema.
# Incluye: git, curl, htop, btop, vim, tmux, fzf, ranger, rclone, etc.
# También instala herramientas avanzadas y configura aliases.
# ─────────────────────────────────────────────────────────────
install_packages() {
    echo -e "${GREEN}>>> Instalando paquetes del sistema y herramientas de terminal...${NC}"
    
    PACKAGES=(
        "git" "curl" "wget" "htop" "btop" "vim" "unzip" "tree" 
        "net-tools" "neofetch" "tmux" "fzf" "ranger" "mc" "rclone"
    )
    
    if [ -f /etc/debian_version ]; then
        echo -e "${CYAN}   Detectado: Debian/Ubuntu (apt)${NC}"
        $SUDO_CMD apt-get update -y
        $SUDO_CMD apt-get install -y "${PACKAGES[@]}" dnsutils w3m-img
    elif [ -f /etc/redhat-release ]; then
        echo -e "${CYAN}   Detectado: Fedora/RHEL (dnf)${NC}"
        $SUDO_CMD dnf install -y "${PACKAGES[@]}" bind-utils w3m-img
    elif [ -f /etc/arch-release ]; then
        echo -e "${CYAN}   Detectado: Arch Linux (pacman)${NC}"
        $SUDO_CMD pacman -Syu --noconfirm "${PACKAGES[@]}" bind w3m
    else
        echo -e "${RED}>>> Sistema no soportado para instalación automática${NC}"
        echo -e "${YELLOW}   Instala manualmente: ${PACKAGES[*]}${NC}"
        return
    fi
    
    # Configurar ranger si está instalado
    if command -v ranger &> /dev/null; then
        if [ ! -d "$HOME/.config/ranger" ]; then
            echo -e "${CYAN}   Configurando ranger...${NC}"
            ranger --copy-config=all
        fi
    fi
    
    echo -e "${CYAN}   ✓ Paquetes base instalados${NC}"
    
    install_terminal_tools
    install_bash_aliases
    
    echo -e "${CYAN}   ✓ Sistema completo configurado${NC}"
}

# ─────────────────────────────────────────────────────────────
# Vincula el archivo .bash_aliases desde config/ al home.
# Crea backup si existe un archivo previo (no symlink).
# ─────────────────────────────────────────────────────────────
install_bash_aliases() {
    echo -e "${GREEN}>>> Vinculando Bash Aliases...${NC}"
    ALIAS_FILE="$HOME/.bash_aliases"
    [ -f "$ALIAS_FILE" ] && [ ! -L "$ALIAS_FILE" ] && mv "$ALIAS_FILE" "$ALIAS_FILE.backup"
    ln -sf "$DOTFILES_DIR/config/.bash_aliases" "$ALIAS_FILE"
    echo -e "${CYAN}   ✓ Aliases configurados${NC}"
}

# ─────────────────────────────────────────────────────────────
# Instala herramientas avanzadas de terminal:
# - lsd: ls moderno con iconos y colores
# - lazydocker: TUI para gestionar Docker
# - ctop: top para containers
# - gping: ping visual con gráficos
# ─────────────────────────────────────────────────────────────
install_terminal_tools() {
    echo -e "${GREEN}>>> Instalando herramientas avanzadas de terminal...${NC}"
    
    # LSD - LSDeluxe
    if ! command -v lsd &> /dev/null; then
        echo -e "${CYAN}   Instalando lsd (ls moderno)...${NC}"
        if [ -f /etc/debian_version ]; then
            LSD_VERSION="1.1.5"
            wget -q "https://github.com/lsd-rs/lsd/releases/download/v${LSD_VERSION}/lsd_${LSD_VERSION}_amd64.deb" -O /tmp/lsd.deb
            $SUDO_CMD dpkg -i /tmp/lsd.deb
            rm /tmp/lsd.deb
        elif [ -f /etc/redhat-release ]; then
            $SUDO_CMD dnf install lsd -y 2>/dev/null || {
                if command -v cargo &> /dev/null; then
                    cargo install lsd
                else
                    echo -e "${YELLOW}   ! lsd no disponible. Instala cargo.${NC}"
                fi
            }
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S lsd --noconfirm
        fi
        echo -e "${CYAN}   ✓ lsd instalado${NC}"
    else
        echo -e "${YELLOW}   ! lsd ya está instalado${NC}"
    fi
    
    # Lazydocker
    if ! command -v lazydocker &> /dev/null; then
        echo -e "${CYAN}   Instalando lazydocker...${NC}"
        curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
        echo -e "${CYAN}   ✓ lazydocker instalado${NC}"
    else
        echo -e "${YELLOW}   ! lazydocker ya está instalado${NC}"
    fi
    
    # Ctop
    if ! command -v ctop &> /dev/null; then
        echo -e "${CYAN}   Instalando ctop...${NC}"
        if [ -f /etc/debian_version ] || [ -f /etc/redhat-release ]; then
            $SUDO_CMD wget -q https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64 -O /usr/local/bin/ctop
            $SUDO_CMD chmod +x /usr/local/bin/ctop
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S ctop --noconfirm
        fi
        echo -e "${CYAN}   ✓ ctop instalado${NC}"
    else
        echo -e "${YELLOW}   ! ctop ya está instalado${NC}"
    fi
    
    # Gping
    if ! command -v gping &> /dev/null; then
        echo -e "${CYAN}   Instalando gping...${NC}"
        if [ -f /etc/debian_version ]; then
            if command -v cargo &> /dev/null; then
                cargo install gping
            else
                echo -e "${YELLOW}   ! gping requiere cargo.${NC}"
            fi
        elif [ -f /etc/redhat-release ]; then
            $SUDO_CMD dnf copr enable atim/gping -y 2>/dev/null || true
            $SUDO_CMD dnf install gping -y 2>/dev/null || true
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S gping --noconfirm
        fi
    else
        echo -e "${YELLOW}   ! gping ya está instalado${NC}"
    fi
    
    echo -e "${CYAN}   ✓ Herramientas de terminal instaladas${NC}"
    echo -e "${CYAN}   Disponibles: lsd, lazydocker, ctop, gping${NC}"
}

# ─────────────────────────────────────────────────────────────
# Instalación agrupada de todo el sistema:
# update + packages + git config + ssh keys
# ─────────────────────────────────────────────────────────────
install_system_all() {
    update_system
    install_packages
    install_gitconfig
    install_ssh_keys
}
