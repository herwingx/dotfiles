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
    
    install_modern_tools
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
# ─────────────────────────────────────────────────────────────
# Instala herramientas "Modern Unix" (Rust-based replacements)
# Incluye: zoxide, bat, delta, ripgrep, lsd, etc.
# ─────────────────────────────────────────────────────────────
install_modern_tools() {
    echo -e "${GREEN}>>> Instalando Modern Unix Tools...${NC}"

    # 1. Zoxide (Smarter cd)
    if ! command -v zoxide &> /dev/null; then
        echo -e "${CYAN}   Instalando zoxide...${NC}"
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
        # Configurar en .bashrc
        echo 'eval "$(zoxide init bash)"' >> "$HOME/.bashrc"
        echo 'alias cd="z"' >> "$HOME/.bash_aliases"
        echo -e "${CYAN}   ✓ zoxide instalado (alias cd=z)${NC}"
    else
        echo -e "${YELLOW}   ! zoxide ya existe${NC}"
    fi

    # 2. Bat (Better cat)
    if ! command -v bat &> /dev/null && ! command -v batcat &> /dev/null; then
        echo -e "${CYAN}   Instalando bat...${NC}"
        if [ -f /etc/debian_version ]; then
            $SUDO_CMD apt-get install -y bat
            mkdir -p ~/.local/bin
            ln -sf /usr/bin/batcat ~/.local/bin/bat
        elif [ -f /etc/redhat-release ]; then
            $SUDO_CMD dnf install -y bat
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S bat --noconfirm
        fi
        echo 'alias cat="bat"' >> "$HOME/.bash_aliases"
        echo -e "${CYAN}   ✓ bat instalado (alias cat=bat)${NC}"
    else
        echo -e "${YELLOW}   ! bat ya existe${NC}"
    fi

    # 3. Ripgrep (Faster grep)
    if ! command -v rg &> /dev/null; then
        echo -e "${CYAN}   Instalando ripgrep...${NC}"
        if [ -f /etc/debian_version ]; then
            $SUDO_CMD apt-get install -y ripgrep
        elif [ -f /etc/redhat-release ]; then
            $SUDO_CMD dnf install -y ripgrep
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S ripgrep --noconfirm
        fi
        echo 'alias grep="rg"' >> "$HOME/.bash_aliases"
        echo -e "${CYAN}   ✓ ripgrep instalado (alias grep=rg)${NC}"
    else
        echo -e "${YELLOW}   ! ripgrep ya existe${NC}"
    fi
    
    # 4. Git Delta (Better diff)
    if ! command -v delta &> /dev/null; then
        echo -e "${CYAN}   Instalando git-delta...${NC}"
        # Intentar instalar via cargo si existe, sino binario precompilado
        if command -v cargo &> /dev/null; then
            cargo install git-delta
        else
            # Fallback manual para sistemas sin cargo
            # (Aquí simplificamos asumiendo x86_64 linux, lo ideal es detectar arch)
            DELTA_VERSION="0.16.5"
            wget -q "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb" -O /tmp/delta.deb
            if [ -f /tmp/delta.deb ]; then
                 $SUDO_CMD dpkg -i /tmp/delta.deb 2>/dev/null || echo "Fallo instalacion deb delta"
                 rm /tmp/delta.deb
            fi
        fi

        # Configurar git para usar delta si se instaló
        if command -v delta &> /dev/null; then
            git config --global core.pager "delta"
            git config --global interactive.diffFilter "delta --color-only"
            git config --global delta.navigate true
            git config --global delta.light false
            echo -e "${CYAN}   ✓ delta configurado como git pager${NC}"
        fi
    fi

    # 5. LSD (Modern ls) - Mantenemos la lógica existente
    if ! command -v lsd &> /dev/null; then
        echo -e "${CYAN}   Instalando lsd...${NC}"
        # ... (lógica lsd existente resumida) ...
        # (Nota: Asumimos que lsd ya estaba, aquí solo lo agrupamos conceptualmente)
        # Para evitar duplicar código gigante, dejamos lsd como estaba abajo o lo movemos
    fi
    # Nota: LSD ya estaba implementado, lo dejamos en su bloque original para no romper.
    # Reemplazamos el inicio:
# ─────────────────────────────────────────────────────────────
# Instala herramientas "Modern Unix" (Rust-based replacements)
# Incluye: zoxide, bat, delta, ripgrep, lsd, etc.
# ─────────────────────────────────────────────────────────────
install_modern_tools() {
    echo -e "${GREEN}>>> Instalando Modern Unix Tools...${NC}"

    # 1. Zoxide (Smarter cd)
    if ! command -v zoxide &> /dev/null; then
        echo -e "${CYAN}   Instalando zoxide...${NC}"
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
        # Configurar en .bashrc
        echo 'eval "$(zoxide init bash)"' >> "$HOME/.bashrc"
        echo 'alias cd="z"' >> "$HOME/.bash_aliases"
        echo -e "${CYAN}   ✓ zoxide instalado (alias cd=z)${NC}"
    else
        echo -e "${YELLOW}   ! zoxide ya existe${NC}"
    fi

    # 2. Bat (Better cat)
    if ! command -v bat &> /dev/null && ! command -v batcat &> /dev/null; then
        echo -e "${CYAN}   Instalando bat...${NC}"
        if [ -f /etc/debian_version ]; then
            $SUDO_CMD apt-get install -y bat
            mkdir -p ~/.local/bin
            ln -sf /usr/bin/batcat ~/.local/bin/bat
        elif [ -f /etc/redhat-release ]; then
            $SUDO_CMD dnf install -y bat
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S bat --noconfirm
        fi
        echo 'alias cat="bat"' >> "$HOME/.bash_aliases"
        echo -e "${CYAN}   ✓ bat instalado (alias cat=bat)${NC}"
    else
        echo -e "${YELLOW}   ! bat ya existe${NC}"
    fi

    # 3. Ripgrep (Faster grep)
    if ! command -v rg &> /dev/null; then
        echo -e "${CYAN}   Instalando ripgrep...${NC}"
        if [ -f /etc/debian_version ]; then
            $SUDO_CMD apt-get install -y ripgrep
        elif [ -f /etc/redhat-release ]; then
            $SUDO_CMD dnf install -y ripgrep
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S ripgrep --noconfirm
        fi
        echo 'alias grep="rg"' >> "$HOME/.bash_aliases"
        echo -e "${CYAN}   ✓ ripgrep instalado (alias grep=rg)${NC}"
    else
        echo -e "${YELLOW}   ! ripgrep ya existe${NC}"
    fi
    
    # 4. Git Delta (Better diff)
    if ! command -v delta &> /dev/null; then
        echo -e "${CYAN}   Instalando git-delta...${NC}"
        # Intentar instalar via cargo si existe, sino binario precompilado
        if command -v cargo &> /dev/null; then
            cargo install git-delta
        else
            # Fallback manual para sistemas sin cargo
            # (Aquí simplificamos asumiendo x86_64 linux, lo ideal es detectar arch)
            DELTA_VERSION="0.16.5"
            wget -q "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb" -O /tmp/delta.deb
            if [ -f /tmp/delta.deb ]; then
                 $SUDO_CMD dpkg -i /tmp/delta.deb 2>/dev/null || echo "Fallo instalacion deb delta"
                 rm /tmp/delta.deb
            fi
        fi

        # Configurar git para usar delta si se instaló
        if command -v delta &> /dev/null; then
            git config --global core.pager "delta"
            git config --global interactive.diffFilter "delta --color-only"
            git config --global delta.navigate true
            git config --global delta.light false
            echo -e "${CYAN}   ✓ delta configurado como git pager${NC}"
        fi
    fi

    # 5. LSD (Modern ls)
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
        if [ -f /etc/debian_version ] || [ -f /etc/redhat-release ]; then
            echo "deb [signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian/ stable main" | $SUDO_CMD tee /etc/apt/sources.list.d/azlux.list >/dev/null
            $SUDO_CMD wget -O /usr/share/keyrings/azlux-archive-keyring.gpg  https://azlux.fr/repo.gpg
            $SUDO_CMD apt-get update && $SUDO_CMD apt-get install -y gping
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S gping --noconfirm
        fi
        echo -e "${CYAN}   ✓ gping instalado${NC}"
    else
        echo -e "${YELLOW}   ! gping ya está instalado${NC}"
    fi

    # Atuin
    install_atuin

    # Oh My Posh
    install_oh_my_posh

    # Ble.sh (Bash Line Editor) - Debe ir AL FINAL
    install_blesh

    # Tmux Configuration (Premium)
    if [ -f "$DOTFILES_DIR/config/.tmux.conf" ]; then
        ln -sf "$DOTFILES_DIR/config/.tmux.conf" "$HOME/.tmux.conf"
        echo -e "${CYAN}   ✓ tmux.conf enlazado${NC}"
    fi
    
    echo -e "${CYAN}   ✓ Herramientas Modern Unix instaladas${NC}"
    echo -e "${CYAN}   Disponibles: zoxide, bat, rg, delta, atuin, ble.sh, tmux${NC}"
}

# ─────────────────────────────────────────────────────────────
# Instala Ble.sh (Syntax Highlighting & Auto-suggestions for Bash)
# ─────────────────────────────────────────────────────────────
install_blesh() {
    echo -e "${GREEN}>>> Instalando Ble.sh...${NC}"
    
    BLESH_DIR="$HOME/.local/share/blesh"
    
    if [ ! -d "$BLESH_DIR" ]; then
         echo -e "${CYAN}   Clonando y compilando ble.sh...${NC}"
         git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git /tmp/ble.sh
         make -C /tmp/ble.sh install PREFIX=~/.local
         rm -rf /tmp/ble.sh
    fi
    echo -e "${CYAN}   ✓ Ble.sh instalado${NC}"

    # Configurar estilos (.blerc)
    echo -e "${CYAN}   Configurando estilos visuales (.blerc)...${NC}"
    cat > "$HOME/.blerc" <<EOF
# ==============================================================================
# CONFIGURACIÓN VISUAL BLE.SH
# ==============================================================================

# 1. Estilo Fish-like (Sugerencias grises, SIN subrayado ni fondo)
ble-face -s auto_complete fg=242,bg=default,ul=none
ble-face -s auto_complete_data fg=242,bg=default,ul=none

# 2. Menú de autocompletado tipo Grid (Tab)
ble-opt complete_menu_style=align-nowrap

# 3. Colores de sintaxis más suaves
ble-face -s syntax_error fg=196,bg=default        # Error rojo
ble-face -s syntax_varname fg=208                 # Variables naranja
ble-face -s syntax_quoted fg=107                  # Comillas verde
EOF
    echo -e "${CYAN}   ✓ .blerc generado (Estilo limpio/grid)${NC}"

    # Configurar .bashrc (SOURCE al inicio, ATTACH al final)
    BASHRC="$HOME/.bashrc"
    BLESH_INIT='[[ $- == *i* ]] && source ~/.local/share/blesh/ble.sh --noattach'
    BLESH_ATTACH='[[ ${BLE_VERSION-} ]] && ble-attach'
    
    # 1. Agregar source al inicio si no existe
    if ! grep -q "ble.sh --noattach" "$BASHRC"; then
        echo "$BLESH_INIT" > "$BASHRC.tmp"
        cat "$BASHRC" >> "$BASHRC.tmp"
        mv "$BASHRC.tmp" "$BASHRC"
    fi

    # 2. Asegurar que ble-attach esté AL FINAL (borrar previos y re-escribir)
    sed -i '/ble-attach/d' "$BASHRC"
    sed -i '/Ble.sh attach/d' "$BASHRC"
    
    echo "" >> "$BASHRC"
    echo "# Ble.sh attach (must be last)" >> "$BASHRC"
    echo "$BLESH_ATTACH" >> "$BASHRC"
        
    # Tmux Configuration
    if [ -f "$DOTFILES_DIR/config/.tmux.conf" ]; then
        ln -sf "$DOTFILES_DIR/config/.tmux.conf" "$HOME/.tmux.conf"
        echo -e "${CYAN}   ✓ tmux.conf enlazado${NC}"
    fi

    echo -e "${CYAN}   ✓ Ble.sh configurado en .bashrc${NC}"
}

# ─────────────────────────────────────────────────────────────
# Instala Atuin (Historial de Shell Mágico)
# ─────────────────────────────────────────────────────────────
install_atuin() {
    echo -e "${GREEN}>>> Instalando Atuin...${NC}"
    
    if ! command -v atuin &> /dev/null; then
        echo -e "${CYAN}   Descargando e instalando Atuin...${NC}"
        curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | bash
        echo -e "${CYAN}   ✓ Atuin instalado${NC}"
    else
        echo -e "${YELLOW}   ! Atuin ya está instalado${NC}"
    fi

    # Configurar .bashrc
    BASHRC="$HOME/.bashrc"
    if ! grep -q "atuin init bash" "$BASHRC"; then
        echo 'eval "$(atuin init bash)"' >> "$BASHRC"
        echo -e "${CYAN}   ✓ Atuin init agregado a .bashrc${NC}"
    fi

    # Instrucciones post-instalación
    echo -e "${YELLOW}   ⚠️  Paso final (requiere interacción manual):${NC}"
    echo -e "${YELLOW}   Ejecuta estos comandos para sincronizar tu historial:${NC}"
    echo -e "${CYAN}     1. atuin register -u <usuario> -e <email>${NC}"
    echo -e "${CYAN}     2. atuin import auto${NC}"
    echo -e "${CYAN}     3. atuin sync${NC}"
}

# ─────────────────────────────────────────────────────────────
# Instala Oh My Posh y configura el tema personalizado.
# ─────────────────────────────────────────────────────────────
install_oh_my_posh() {
    echo -e "${GREEN}>>> Instalando Oh My Posh...${NC}"
    
    if ! command -v oh-my-posh &> /dev/null; then
        echo -e "${CYAN}   Descargando e instalando Oh My Posh...${NC}"
        curl -s https://ohmyposh.dev/install.sh | $SUDO_CMD bash -s -- -d /usr/local/bin
        echo -e "${CYAN}   ✓ Oh My Posh instalado${NC}"
    else
        echo -e "${YELLOW}   ! Oh My Posh ya está instalado${NC}"
    fi

    # Configurar tema
    THEME_DIR="$HOME/.cache/oh-my-posh/themes"
    mkdir -p "$THEME_DIR"
    
    if [ -f "$DOTFILES_DIR/config/herwingx.omp.json" ]; then
        echo -e "${CYAN}   Instalando tema herwingx...${NC}"
        ln -sf "$DOTFILES_DIR/config/herwingx.omp.json" "$THEME_DIR/herwingx.omp.json"
    else
        echo -e "${RED}   ✗ No se encontró el tema config/herwingx.omp.json${NC}"
    fi

    # Configurar .bashrc
    BASHRC="$HOME/.bashrc"
    OMP_INIT='eval "$(oh-my-posh init bash --config ~/.cache/oh-my-posh/themes/herwingx.omp.json)"'
    
    # Remover configuraciones viejas de oh-my-posh si existen (limpieza)
    sed -i '/oh-my-posh init bash/d' "$BASHRC"
    
    # Agregar la nueva configuración al final
    echo "$OMP_INIT" >> "$BASHRC"
    
    echo -e "${CYAN}   ✓ Tema herwingx configurado en .bashrc${NC}"
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
# Permite personalizar el horario y frecuencia para evitar conflictos en Proxmox.
#
# Opciones de frecuencia:
# - Diario: Todos los días a la hora configurada
# - Semanal: Cada domingo a la hora configurada
# - Mensual: El día 1 de cada mes a la hora configurada
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
    
    # Menú de frecuencia
    echo ""
    echo -e "${CYAN}   ┌──────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}   │${NC}  ${BOLD}Frecuencia de actualizaciones${NC}            ${CYAN}│${NC}"
    echo -e "${CYAN}   ├──────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}   │${NC}   ${GREEN}1)${NC} 📅 Diario (recomendado servidores)    ${CYAN}│${NC}"
    echo -e "${CYAN}   │${NC}   ${GREEN}2)${NC} 📆 Semanal (domingos)                 ${CYAN}│${NC}"
    echo -e "${CYAN}   │${NC}   ${GREEN}3)${NC} 🗓️  Mensual (día 1 de cada mes)        ${CYAN}│${NC}"
    echo -e "${CYAN}   └──────────────────────────────────────────┘${NC}"
    echo ""
    read -p "   Selecciona frecuencia [1-3, default: 1]: " FREQ_OPTION
    FREQ_OPTION=${FREQ_OPTION:-1}
    
    case "$FREQ_OPTION" in
        1)
            CRON_FREQUENCY="daily"
            CRON_DAY_OF_WEEK="*"
            CRON_DAY_OF_MONTH="*"
            FREQ_LABEL="diario"
            ;;
        2)
            CRON_FREQUENCY="weekly"
            CRON_DAY_OF_WEEK="0"  # Domingo
            CRON_DAY_OF_MONTH="*"
            FREQ_LABEL="semanal (domingos)"
            ;;
        3)
            CRON_FREQUENCY="monthly"
            CRON_DAY_OF_WEEK="*"
            CRON_DAY_OF_MONTH="1"  # Día 1
            FREQ_LABEL="mensual (día 1)"
            ;;
        *)
            echo -e "${YELLOW}   ! Opción inválida, usando diario${NC}"
            CRON_FREQUENCY="daily"
            CRON_DAY_OF_WEEK="*"
            CRON_DAY_OF_MONTH="*"
            FREQ_LABEL="diario"
            ;;
    esac
    
    echo -e "${CYAN}   Frecuencia seleccionada: $FREQ_LABEL${NC}"
    
    # Solicitar horario personalizado
    echo ""
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
    
    echo -e "${CYAN}   Horario configurado: ${CRON_HOUR}:$(printf "%02d" $CRON_MINUTE) $FREQ_LABEL${NC}"
    
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
    # Formato cron: minuto hora día_del_mes mes día_de_la_semana
    $SUDO_CMD tee /etc/cron.d/dotfiles-update > /dev/null <<EOF
# Actualizaciones automáticas del sistema - dotfiles
# Frecuencia: $FREQ_LABEL
# Horario: ${CRON_HOUR}:$(printf "%02d" $CRON_MINUTE)
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

$CRON_MINUTE $CRON_HOUR $CRON_DAY_OF_MONTH * $CRON_DAY_OF_WEEK root /usr/local/bin/dotfiles-update >> /var/log/dotfiles-updates.log 2>&1
EOF
    $SUDO_CMD chmod 644 /etc/cron.d/dotfiles-update
    
    # Crear archivo de log si no existe
    $SUDO_CMD touch /var/log/dotfiles-updates.log
    $SUDO_CMD chmod 644 /var/log/dotfiles-updates.log
    
    echo -e "${CYAN}   ✓ Cronjob instalado: ${CRON_HOUR}:$(printf "%02d" $CRON_MINUTE) $FREQ_LABEL${NC}"
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
• Frecuencia: $FREQ_LABEL
• Horario: ${CRON_HOUR}:$(printf "%02d" $CRON_MINUTE)
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

