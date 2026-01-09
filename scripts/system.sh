#!/bin/bash
# También instala herramientas avanzadas y configura aliases.
# ─────────────────────────────────────────────────────────────
install_packages() {
    echo -e "${GREEN}>>> Instalando paquetes del sistema y herramientas de terminal...${NC}"
    
    PACKAGES=(
        "git" "curl" "wget" "htop" "btop" "vim" "unzip" "tree" 
        "net-tools" "neofetch" "tmux" "fzf" "ranger" "mc" "rclone"
        "make" "gawk" "gcc" "xz-utils" "micro" "tldr"
    )
    
    if [ -f /etc/debian_version ]; then
        echo -e "${CYAN}   Detectado: Debian/Ubuntu (apt)${NC}"
        $SUDO_CMD apt-get update -y
        $SUDO_CMD apt-get install -y "${PACKAGES[@]}" build-essential dnsutils w3m-img
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

    # Actualizar base de datos de tldr (si se instaló)
    if command -v tldr &> /dev/null; then
        echo -e "${CYAN}   Actualizando base de datos tldr...${NC}"
        tldr --update &>/dev/null || true
    fi
    
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
# Instala herramientas "Modern Unix" (Rust-based replacements)
# Incluye: zoxide, bat, delta, ripgrep, lsd, etc.
# ─────────────────────────────────────────────────────────────
install_modern_tools() {
    echo -e "${GREEN}>>> Instalando Modern Unix Tools...${NC}"

    # 1. Zoxide (Smarter cd)
    if ! command -v zoxide &> /dev/null; then
        echo -e "${CYAN}   Instalando zoxide...${NC}"
        
        # Intentar primero por gestor de paquetes (más fiable en LXC)
        if [ -f /etc/debian_version ]; then
            $SUDO_CMD apt-get install -y zoxide 2>/dev/null
        elif [ -f /etc/redhat-release ]; then
            $SUDO_CMD dnf install -y zoxide 2>/dev/null
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S zoxide --noconfirm 2>/dev/null
        fi

        # Si aún no existe (versión vieja de distro), usar el script oficial
        if ! command -v zoxide &> /dev/null; then
            echo -e "${YELLOW}   ! No disponible en repo. Usando script de instalación...${NC}"
            curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
        fi

        # Asegurar PATH para ~/.local/bin (donde instala el script fallback)
        if ! grep -q ".local/bin" "$HOME/.bashrc"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        fi

        # Configurar en .bashrc
        if ! grep -q "zoxide init bash" "$HOME/.bashrc"; then
            echo 'eval "$(zoxide init bash)"' >> "$HOME/.bashrc"
        fi
        
        if ! grep -q 'alias cd="z"' "$HOME/.bash_aliases"; then
            # Ya no añadimos al archivo vía echo para evitar ensuciar el git
            echo -e "${CYAN}   ℹ Alias cd=z gestionado en .bash_aliases¹${NC}"
        fi
        
        echo -e "${CYAN}   ✓ zoxide configurado (alias cd=z)${NC}"
    else
        echo -e "${YELLOW}   ! zoxide ya existe${NC}"
    fi

    # 2. Bat (Better cat)
    if ! command -v bat &> /dev/null && ! command -v batcat &> /dev/null; then
        echo -e "${CYAN}   Instalando bat...${NC}"
        if [ -f /etc/debian_version ]; then
            $SUDO_CMD apt-get install -y bat
        elif [ -f /etc/redhat-release ]; then
            $SUDO_CMD dnf install -y bat
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S bat --noconfirm
        fi
        echo -e "${CYAN}   ✓ bat instalado${NC}"
    else
        echo -e "${YELLOW}   ! bat ya existe${NC}"
    fi

    # 3. Ripgrep (rg)
    if ! command -v rg &> /dev/null; then
        echo -e "${CYAN}   Instalando ripgrep...${NC}"
        if [ -f /etc/debian_version ]; then
            $SUDO_CMD apt-get install -y ripgrep
        elif [ -f /etc/redhat-release ]; then
            $SUDO_CMD dnf install -y ripgrep
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S ripgrep --noconfirm
        fi
        echo -e "${CYAN}   ✓ ripgrep instalado${NC}"
    else
        echo -e "${YELLOW}   ! ripgrep ya existe${NC}"
    fi

    # 4. LSD (LSDeluxe)
    if ! command -v lsd &> /dev/null; then
        echo -e "${CYAN}   Instalando lsd...${NC}"
        if [ -f /etc/debian_version ]; then
            $SUDO_CMD apt-get install -y lsd
        elif [ -f /etc/redhat-release ]; then
            $SUDO_CMD dnf install -y lsd
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S lsd --noconfirm
        fi
        echo -e "${CYAN}   ✓ lsd instalado${NC}"
    else
        echo -e "${YELLOW}   ! lsd ya existe${NC}"
    fi

    # 5. Delta (Better git diff)
    if ! command -v delta &> /dev/null; then
        echo -e "${CYAN}   Instalando git-delta...${NC}"
        if [ -f /etc/debian_version ]; then
            $SUDO_CMD apt-get install -y git-delta
        elif [ -f /etc/redhat-release ]; then
            $SUDO_CMD dnf install -y git-delta
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S git-delta --noconfirm
        fi
        echo -e "${CYAN}   ✓ delta instalado${NC}"
    else
        echo -e "${YELLOW}   ! delta ya existe${NC}"
    fi

    # 6. Gping (Visual ping)
    if ! command -v gping &> /dev/null; then
        echo -e "${CYAN}   Instalando gping...${NC}"
        if [ -f /etc/debian_version ]; then
             # Para Debian/Ubuntu hay que añadir repo o usar binario
             # Intentar apt primero (en versiones nuevas está)
             $SUDO_CMD apt-get install -y gping 2>/dev/null || {
                echo -e "${YELLOW}   ! gping no está en repo apt. Saltando o instala vía cargo.${NC}"
             }
        elif [ -f /etc/redhat-release ]; then
            $SUDO_CMD dnf install -y gping 2>/dev/null
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S gping --noconfirm 2>/dev/null
        fi
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
    echo -e "${GREEN}>>> Instalando Ble.sh (Bash Line Editor)...${NC}"
    
    BLESH_DIR="$HOME/.local/share/blesh"
    
    # 1. Instalación/Compilación robusta
    if [ ! -d "$BLESH_DIR" ] || [ ! -f "$BLESH_DIR/ble.sh" ]; then
         echo -e "${CYAN}   Clonando y compilando ble.sh...${NC}"
         rm -rf /tmp/ble.sh
         if ! git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git /tmp/ble.sh; then
             echo -e "${RED}   ✗ Error al clonar ble.sh${NC}"
             return 1
         fi

         # Compilar e instalar (usando PREFIX local)
         if make -C /tmp/ble.sh install PREFIX=~/.local; then
             echo -e "${CYAN}   ✓ Ble.sh instalado exitosamente${NC}"
         else
             echo -e "${RED}   ✗ Error al compilar ble.sh. Verifica: make, gcc, gawk.${NC}"
             rm -rf /tmp/ble.sh
             return 1
         fi
         rm -rf /tmp/ble.sh
    fi

    # 2. Configurar estilos y comportamiento (.blerc)
    echo -e "${CYAN}   Configurando .blerc (Estabilidad y Silencio)...${NC}"
    cat > "$HOME/.blerc" <<'EOF'
# Función para establecer opciones de forma segura (sin errores si no existen)
_safe_bleopt() {
    local opt=$1 val=$2
    if bleopt "$opt" >/dev/null 2>&1; then
        bleopt "$opt=$val"
    fi
}

# Configuración visual
_safe_bleopt complete_auto_complete 1
_safe_bleopt complete_menu_style align-nowrap

# 🛠️ SOLUCIÓN AL "FANTASMA" DEL TAB:
# Forzar a que la sugerencia desaparezca al insertar el completado real
_safe_bleopt complete_auto_history 1
_safe_bleopt complete_ambiguous ""

# Ocultar el mensaje de estado de salida [ble: exit XXX]
_safe_bleopt exec_exit_status ""
_safe_bleopt print_exit_status 0

# Colores limpios (gris suave para sugerencias)
if [[ ${BLE_VERSION-} ]]; then
    ble-face -s auto_complete fg=242,bg=default,ul=none
    ble-face -s syntax_error fg=196,bg=default
    ble-face -s syntax_varname fg=208
    ble-face -s syntax_quoted fg=107
fi
EOF

    # 3. Configurar .bashrc de forma atómica y segura
    if [ -f "$BLESH_DIR/ble.sh" ]; then
        BASHRC="$HOME/.bashrc"
        
        # Definir bloques de código con checks de interactividad estrictos
        # El SOURCE debe ir al principio (redirigimos stderr para silenciar caché de tput)
        BLE_SOURCE_BLOCK='[[ $- == *i* && -f ~/.local/share/blesh/ble.sh ]] && source ~/.local/share/blesh/ble.sh --noattach 2>/dev/null'
        # El ATTACH debe ir al final
        BLE_ATTACH_BLOCK='[[ ${BLE_VERSION-} ]] && ble-attach'

        # Limpiar entradas previas para evitar duplicidad o desorden
        sed -i '/ble.sh/d' "$BASHRC"
        sed -i '/ble-attach/d' "$BASHRC"
        sed -i '/Ble.sh attach/d' "$BASHRC"

        # Inyectar SOURCE al inicio (creamos archivo temporal)
        {
            echo "$BLE_SOURCE_BLOCK"
            cat "$BASHRC"
        } > "$BASHRC.tmp" && mv "$BASHRC.tmp" "$BASHRC"

        # Inyectar ATTACH al final
        echo "" >> "$BASHRC"
        echo "# Ble.sh attach (Debe ser la última línea)" >> "$BASHRC"
        echo "$BLE_ATTACH_BLOCK" >> "$BASHRC"
        
        echo -e "${CYAN}   ✓ .bashrc configurado (Source al inicio, Attach al final)${NC}"
    else
        echo -e "${RED}   ✗ No se encontró ble.sh tras la instalación${NC}"
    fi
}

# ─────────────────────────────────────────────────────────────
# Instala Atuin (Historial de Shell Mágico)
# ─────────────────────────────────────────────────────────────
install_atuin() {
    echo -e "${GREEN}>>> Instalando Atuin...${NC}"
    
    if ! command -v atuin &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | sh
        
        # Atuin normalmente se añade solo al bashrc, pero verificamos
        if ! grep -q "atuin init bash" "$HOME/.bashrc"; then
            echo 'eval "$(atuin init bash)"' >> "$HOME/.bashrc"
        fi
        echo -e "${CYAN}   ✓ Atuin instalado${NC}"
    else
        echo -e "${YELLOW}   ! Atuin ya existe${NC}"
    fi
}

# ─────────────────────────────────────────────────────────────
# Instala Oh My Posh (Custom Prompt)
# ─────────────────────────────────────────────────────────────
install_oh_my_posh() {
    echo -e "${GREEN}>>> Instalando Oh My Posh...${NC}"
    
    if ! command -v oh-my-posh &> /dev/null; then
        $SUDO_CMD curl -s https://ohmyposh.dev/install.sh | bash -s -- -d /usr/local/bin
    fi
    
    # Configurar el tema herwingx
    THEME_FILE="$DOTFILES_DIR/config/herwingx.omp.json"
    if [ -f "$THEME_FILE" ]; then
        # Asegurar que la línea de init esté en .bashrc
        if ! grep -q "oh-my-posh init bash" "$HOME/.bashrc"; then
            echo "eval \"\$(oh-my-posh init bash --config $THEME_FILE)\"" >> "$HOME/.bashrc"
        fi
        echo -e "${CYAN}   ✓ Oh My Posh configurado con tema herwingx${NC}"
    else
        echo -e "${YELLOW}   ! No se encontró el tema $THEME_FILE. Saltando config.${NC}"
    fi
}
