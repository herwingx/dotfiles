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
    
    # Limpiar PATH en WSL (eliminar rutas de Windows)
    configure_wsl_path
}

# ─────────────────────────────────────────────────────────────
# Configura el PATH en WSL para excluir binarios de Windows.
# Esto evita conflictos como el de Gemini detectando nvm4w.
# ─────────────────────────────────────────────────────────────
configure_wsl_path() {
    # Detectar si estamos en WSL
    if [ ! -f /proc/version ] || ! grep -qi microsoft /proc/version; then
        return  # No estamos en WSL, salir
    fi
    
    echo -e "${CYAN}   Detectado WSL. Limpiando PATH de rutas de Windows...${NC}"
    
    BASHRC="$HOME/.bashrc"
    
    # Verificar si ya existe la configuración
    if grep -q "# WSL: Limpiar PATH de Windows" "$BASHRC"; then
        echo -e "${YELLOW}   ! PATH de WSL ya configurado${NC}"
        return
    fi
    
    # Agregar al .bashrc la limpieza de PATH
    cat >> "$BASHRC" <<'EOF'

# WSL: Limpiar PATH de Windows (evitar conflictos con binarios .exe)
if grep -qi microsoft /proc/version 2>/dev/null; then
    # Filtrar rutas de /mnt/* del PATH
    NEW_PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '^/mnt/' | tr '\n' ':' | sed 's/:$//')
    export PATH="$NEW_PATH"
fi
EOF
    
    echo -e "${CYAN}   ✓ PATH configurado para ignorar binarios de Windows${NC}"
    echo -e "${YELLOW}   ⚠️  Recarga tu shell (source ~/.bashrc) para aplicar cambios${NC}"
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
            mkdir -p ~/.local/bin
            ln -sf /usr/bin/batcat ~/.local/bin/bat
        elif [ -f /etc/redhat-release ]; then
            $SUDO_CMD dnf install -y bat
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S bat --noconfirm
        fi
        echo -e "${CYAN}   ✓ bat instalado${NC}"
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
        echo -e "${CYAN}   ✓ ripgrep instalado${NC}"
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
    
    # Configuración de Google Antigravity (WSL Fix)
    install_antigravity_fix

    echo -e "${CYAN}   ✓ Herramientas Modern Unix instaladas${NC}"
    echo -e "${CYAN}   Disponibles: zoxide, bat, rg, delta, atuin, ble.sh, tmux, agy${NC}"
}

# ─────────────────────────────────────────────────────────────
# Configura Google Antigravity (agy) en WSL.
# - Crea symlink al ejecutable de Windows.
# - Parchea el archivo de lanzamiento para corregir el bug de ID de extensión.
# ─────────────────────────────────────────────────────────────
install_antigravity_fix() {
    # Solo ejecutar en WSL
    if ! grep -qi microsoft /proc/version 2>/dev/null; then
        return
    fi

    echo -e "${GREEN}>>> Configurando Google Antigravity (agy) para WSL...${NC}"
    
    # 1. Detectar usuario de Windows dinámicamente
    # cmd.exe devuelve el usuario con retorno de carro (\r), hay que limpiarlo.
    WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
    
    if [ -n "$WIN_USER" ]; then
        # Ruta estándar de instalación en Windows (accedida desde /mnt/c)
        AGY_PATH="/mnt/c/Users/$WIN_USER/AppData/Local/Programs/Antigravity/bin/antigravity"
        
        if [ -f "$AGY_PATH" ]; then
            # 2. Crear Symlink en ~/.local/bin
            # Forzamos la creación del directorio por si acaso
            mkdir -p "$HOME/.local/bin"
            
            # Eliminamos link previo si existe y creamos uno nuevo
            rm -f "$HOME/.local/bin/agy"
            ln -s "$AGY_PATH" "$HOME/.local/bin/agy"
            echo -e "${CYAN}   ✓ Symlink 'agy' vinculado al ejecutable de Windows${NC}"
            
            # 3. Parchear el bug de WSL_EXT_ID (Fix Smart)
            # Solo parcheamos si detectamos que la estructura de archivos soporta el nuevo ID
            # o si el usuario ya lo tenía parcheado.
            
            BASE_DIR="$(dirname "$(dirname "$AGY_PATH")")"
            EXT_DIR="$BASE_DIR/resources/app/extensions"
            
            # Nombres posibles de la carpeta de extensión
            NEW_EXT_FOLDER="antigravity-remote-wsl" # Lo que busca el script con el nuevo ID
            OLD_EXT_FOLDER="ms-vscode-remote.remote-wsl"
            
            if grep -q "WSL_EXT_ID=\"ms-vscode-remote.remote-wsl\"" "$AGY_PATH"; then
                if [ -d "$EXT_DIR/$NEW_EXT_FOLDER" ]; then
                    echo -e "${YELLOW}   ! Bug detectado y estructura compatible. Aplicando parche...${NC}"
                    cp "$AGY_PATH" "${AGY_PATH}.bak"
                    sed -i 's/WSL_EXT_ID="ms-vscode-remote.remote-wsl"/WSL_EXT_ID="google.antigravity-remote-wsl"/' "$AGY_PATH"
                    echo -e "${CYAN}   ✓ Parche aplicado: 'agy' usará la extensión nativa${NC}"
                elif [ -d "$EXT_DIR/$OLD_EXT_FOLDER" ]; then
                    echo -e "${YELLOW}   ! Advertencia: ID incorrecto pero carpeta antigua detectada.${NC}"
                    echo -e "${YELLOW}     No se aplicó el parche para evitar romper el inicio (Error 127).${NC}"
                    echo -e "${YELLOW}     Solución manual: Renombrar carpeta '$OLD_EXT_FOLDER' a '$NEW_EXT_FOLDER' en Windows.${NC}"
                else
                     echo -e "${YELLOW}   ! No se encontraron extensiones en $EXT_DIR. Omitiendo parche.${NC}"
                fi
            elif grep -q "WSL_EXT_ID=\"google.antigravity-remote-wsl\"" "$AGY_PATH"; then
                 echo -e "${CYAN}   ✓ Antigravity ya está parcheado${NC}"
            fi

        else
            echo -e "${RED}   ✗ No se encontró Antigravity en: $AGY_PATH${NC}"
            echo -e "${YELLOW}     Verifica que esté instalado en la ruta por defecto.${NC}"
        fi
    else
        echo -e "${RED}   ✗ No se pudo detectar el usuario de Windows automáticamente${NC}"
    fi
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
    # Añadimos opciones para silenciar mensajes técnicos y mejorar compatibilidad
    echo -e "${CYAN}   Configurando .blerc (Estabilidad y Silencio)...${NC}"
    cat > "$HOME/.blerc" <<'EOF'
# Función para establecer opciones de forma segura (sin errores si no existen)
_safe_bleopt() {
    local opt=$1 val=$2
    if bleopt "$opt" >/dev/null 2>&1; then
        bleopt "$opt=$val"
    fi
}

# DESACTIVAR modo multilínea - Enter siempre ejecuta el comando
ble-bind -f 'C-m' 'accept-line'
ble-bind -f 'RET' 'accept-line'

# DESACTIVAR sugerencias inline (evita duplicación con TAB)
_safe_bleopt complete_auto_complete 0

# Menú de completado limpio (solo con TAB)
_safe_bleopt complete_menu_style desc-raw

# Ocultar el mensaje de estado de salida [ble: exit XXX]
_safe_bleopt exec_exit_status ""
_safe_bleopt print_exit_status 0
bleopt exec_elapsed_mark=

# Colores limpios (syntax highlighting sigue activo)
if [[ ${BLE_VERSION-} ]]; then
    ble-face -s syntax_error fg=196,bg=default
    ble-face -s syntax_varname fg=208
    ble-face -s syntax_quoted fg=107
    ble-face -s command_builtin fg=green
    ble-face -s command_file fg=cyan
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

