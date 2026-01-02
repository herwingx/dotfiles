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
    show_reload_message
}

# ─────────────────────────────────────────────────────────────
# Configura el cronjob de actualizaciones automáticas.
# Permite personalizar el horario para evitar conflictos en Proxmox.
#
# El cronjob ejecuta cron-update.sh que:
# - Actualiza el sistema (apt/dnf/pacman)
# - Notifica via Telegram
# - Reinicia si hay actualización de kernel
# ─────────────────────────────────────────────────────────────
install_auto_update() {
    echo -e "${GREEN}>>> Configurando actualizaciones automáticas...${NC}"
    
    # Verificar que existan las credenciales de Telegram
    decrypt_secrets
    if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
        echo -e "${RED}   ✗ Credenciales de Telegram no encontradas en .env.age${NC}"
        echo -e "${YELLOW}   Agrega TELEGRAM_BOT_TOKEN y TELEGRAM_CHAT_ID a ~/.env.age${NC}"
        return 1
    fi
    
    # Solicitar horario personalizado
    echo -e "${CYAN}   Configuración del horario de actualización:${NC}"
    echo -e "${YELLOW}   (Importante: En Proxmox, usa horarios diferentes para PVE y guests)${NC}"
    echo ""
    
    read -p "   Hora (0-23) [default: 3]: " CRON_HOUR
    CRON_HOUR=${CRON_HOUR:-3}
    
    read -p "   Minuto (0-59) [default: 0]: " CRON_MINUTE
    CRON_MINUTE=${CRON_MINUTE:-0}
    
    # Validar entrada
    if ! [[ "$CRON_HOUR" =~ ^[0-9]+$ ]] || [ "$CRON_HOUR" -gt 23 ]; then
        echo -e "${RED}   ✗ Hora inválida, usando 3${NC}"
        CRON_HOUR=3
    fi
    
    if ! [[ "$CRON_MINUTE" =~ ^[0-9]+$ ]] || [ "$CRON_MINUTE" -gt 59 ]; then
        echo -e "${RED}   ✗ Minuto inválido, usando 0${NC}"
        CRON_MINUTE=0
    fi
    
    echo -e "${CYAN}   Horario configurado: ${CRON_HOUR}:$(printf "%02d" $CRON_MINUTE) diario${NC}"
    
    # Copiar script de actualización a /usr/local/bin
    echo -e "${CYAN}   Instalando script de actualización...${NC}"
    $SUDO_CMD cp "$DOTFILES_DIR/scripts/cron-update.sh" /usr/local/bin/dotfiles-update
    $SUDO_CMD chmod +x /usr/local/bin/dotfiles-update
    
    # Crear archivo de configuración con credenciales de Telegram
    echo -e "${CYAN}   Configurando credenciales de Telegram...${NC}"
    $SUDO_CMD tee /etc/dotfiles-telegram.env > /dev/null <<EOF
# Credenciales de Telegram para notificaciones de actualizaciones
# Generado por dotfiles installer
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID
EOF
    $SUDO_CMD chmod 600 /etc/dotfiles-telegram.env
    
    # Configurar cronjob
    echo -e "${CYAN}   Configurando cronjob...${NC}"
    
    # Crear directorio /etc/cron.d/ si no existe (para WSL)
    $SUDO_CMD mkdir -p /etc/cron.d
    
    # Crear archivo cron en /etc/cron.d/
    $SUDO_CMD tee /etc/cron.d/dotfiles-update > /dev/null <<EOF
# Actualizaciones automáticas del sistema - dotfiles
# Horario: ${CRON_HOUR}:$(printf "%02d" $CRON_MINUTE) diario
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

$CRON_MINUTE $CRON_HOUR * * * root /usr/local/bin/dotfiles-update >> /var/log/dotfiles-updates.log 2>&1
EOF
    $SUDO_CMD chmod 644 /etc/cron.d/dotfiles-update
    
    # Crear archivo de log si no existe
    $SUDO_CMD touch /var/log/dotfiles-updates.log
    $SUDO_CMD chmod 644 /var/log/dotfiles-updates.log
    
    echo -e "${CYAN}   ✓ Cronjob instalado: ${CRON_HOUR}:$(printf "%02d" $CRON_MINUTE) diario${NC}"
    echo -e "${CYAN}   ✓ Script: /usr/local/bin/dotfiles-update${NC}"
    echo -e "${CYAN}   ✓ Log: /var/log/dotfiles-updates.log${NC}"
    echo -e "${CYAN}   ✓ Cron: /etc/cron.d/dotfiles-update${NC}"
    
    # Enviar notificación de prueba
    echo -e "${CYAN}   Enviando notificación de prueba a Telegram...${NC}"
    
    # Usar $HOSTNAME en lugar de $(hostname) para compatibilidad
    CURRENT_HOST="${HOSTNAME:-$(cat /etc/hostname 2>/dev/null || echo 'unknown')}"
    
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="🔧 <b>[$CURRENT_HOST]</b>
Actualizaciones automáticas configuradas.
• Horario: ${CRON_HOUR}:$(printf "%02d" $CRON_MINUTE) diario
• Log: /var/log/dotfiles-updates.log" \
        -d parse_mode="HTML" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CYAN}   ✓ Notificación de prueba enviada${NC}"
    else
        echo -e "${YELLOW}   ! No se pudo enviar notificación de prueba${NC}"
    fi
    
    echo -e "${GREEN}>>> Actualizaciones automáticas configuradas${NC}"
}

# ─────────────────────────────────────────────────────────────
# Desinstala el cronjob de actualizaciones automáticas.
# ─────────────────────────────────────────────────────────────
uninstall_auto_update() {
    echo -e "${GREEN}>>> Desinstalando actualizaciones automáticas...${NC}"
    
    $SUDO_CMD rm -f /etc/cron.d/dotfiles-update
    $SUDO_CMD rm -f /usr/local/bin/dotfiles-update
    $SUDO_CMD rm -f /etc/dotfiles-telegram.env
    
    echo -e "${CYAN}   ✓ Cronjob eliminado${NC}"
    echo -e "${YELLOW}   Nota: El log /var/log/dotfiles-updates.log se mantiene${NC}"
}

# ─────────────────────────────────────────────────────────────
# Ejecuta manualmente una actualización (para testing).
# ─────────────────────────────────────────────────────────────
run_manual_update() {
    echo -e "${GREEN}>>> Ejecutando actualización manual...${NC}"
    
    if [ -f /usr/local/bin/dotfiles-update ]; then
        $SUDO_CMD /usr/local/bin/dotfiles-update
    else
        echo -e "${RED}   ✗ Script no instalado. Ejecuta primero la opción de instalar auto-update${NC}"
    fi
}

