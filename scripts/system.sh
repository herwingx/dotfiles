#!/bin/bash
# ==========================================
# SYSTEM - Actualización y paquetes del sistema
# ==========================================
# Funciones para actualizar el sistema operativo e instalar
# paquetes base mediante ensure_package (idempotente).
# ==========================================

# ─────────────────────────────────────────────────────────────
# Actualiza el sistema operativo de forma inteligente
# ─────────────────────────────────────────────────────────────
fix_locales() {
    if [ "$OS_TYPE" == "debian" ]; then
        print_info "Verificando locales..."
        if ! locale -a | grep -q "en_US.utf8"; then
            print_warning "Locales faltantes. Generando en_US.UTF-8..."
            ensure_package "locales"
            $SUDO_CMD locale-gen en_US.UTF-8
            $SUDO_CMD update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
            export LANG=en_US.UTF-8
            export LC_ALL=en_US.UTF-8
            print_success "Locales generados"
        fi
    fi
}

update_system() {
    # Check manual skip flag
    if [ "$1" == "--force" ]; then
        FORCE_UPDATE=true
    fi

    # Lógica de "cache" de update (Smart Update)
    UPDATE_STATE_FILE="$HOME/.local/state/dotfiles/last_update"
    mkdir -p "$(dirname "$UPDATE_STATE_FILE")"
    
    # Si existe el fichero y tiene menos de 24h (86400 segundos), saltar
    if [ -f "$UPDATE_STATE_FILE" ] && [ "$FORCE_UPDATE" != "true" ]; then
        LAST_UPDATE=$(cat "$UPDATE_STATE_FILE")
        NOW=$(date +%s)
        DIFF=$((NOW - LAST_UPDATE))
        
        if [ $DIFF -lt 86400 ]; then
             print_info "Skip Update: Last update was $(($DIFF / 3600)) hours ago."
             echo -e "${GRAY}      Use 'update_system --force' to override.${NC}"
             return
        fi
    fi

    print_step "Actualizando el sistema ($OS_TYPE)..."
    
    # Fix Locales first
    fix_locales
    
    # Ejecutar actualización global
    $PKG_UPDATE_CMD
    
    if [ "$OS_TYPE" == "debian" ]; then
        $SUDO_CMD apt-get upgrade -y
        $SUDO_CMD apt-get autoremove -y
    elif [ "$OS_TYPE" == "redhat" ]; then
        $SUDO_CMD dnf upgrade -y
        $SUDO_CMD dnf autoremove -y
    fi
    
    # Guardar timestamp
    date +%s > "$UPDATE_STATE_FILE"
    
    print_success "Sistema actualizado"
}

# ─────────────────────────────────────────────────────────────
# Instala paquetes esenciales del sistema usando ensure_package
# ─────────────────────────────────────────────────────────────
install_packages() {
    print_step "Instalando paquetes base del sistema..."
    
    # Paquetes Comunes
    # Nota: Modern Tools (lsd, bat, ripgrep, zoxide) removidos de aquí
    # porque ahora se gestionan via MISE en toolchain.sh
    PACKAGES=(
        "git" "curl" "wget" "unzip" "tree" 
        "net-tools" "tmux" "ranger" "mc" 
        "make" "tar" "jq" "xclip"
    )

    # Distro-specific additions
    case "$OS_TYPE" in
        debian)
            PACKAGES+=("build-essential" "dnsutils" "age" "locales")
            ;;
        redhat)
            PACKAGES+=("gcc" "xz" "bind-utils" "age")
            # Group install logic check
            $SUDO_CMD dnf group install -y "Development Tools" --skip-broken 2>/dev/null
            ;;
        arch)
            PACKAGES+=("base-devel" "bind" "age")
            ;;
    esac

    # Instalación Iterativa e Idempotente
    for pkg in "${PACKAGES[@]}"; do
        ensure_package "$pkg"
    done
    
    # Configurar ranger si está instalado
    if command -v ranger &> /dev/null; then
        if [ ! -d "$HOME/.config/ranger" ]; then
            print_info "Configurando ranger..."
            ranger --copy-config=all
        fi
    fi
    
    print_success "Paquetes base instalados"

    install_bash_aliases
    
    # Atuin y Oh My Posh ahora se gestionan via Mise (toolchain.sh)
    # Solo configuramos sus integraciones aquí
    configure_atuin
    configure_oh_my_posh
    
    # Ble.sh sigue siendo un script custom (sin soporte mise estable aun)
    install_blesh
    
    # Tmux Configuration
    if [ -f "$DOTFILES_DIR/config/.tmux.conf" ]; then
        ln -sf "$DOTFILES_DIR/config/.tmux.conf" "$HOME/.tmux.conf"
    fi
    
    install_antigravity_fix
}

# ─────────────────────────────────────────────────────────────
# Vincula el archivo .bash_aliases
# ─────────────────────────────────────────────────────────────
install_bash_aliases() {
    print_step "Vinculando Bash Aliases..."
    ALIAS_FILE="$HOME/.bash_aliases"
    [ -f "$ALIAS_FILE" ] && [ ! -L "$ALIAS_FILE" ] && mv "$ALIAS_FILE" "$ALIAS_FILE.backup"
    ln -sf "$DOTFILES_DIR/config/.bash_aliases" "$ALIAS_FILE"
    
    # Asegurar carga en .bashrc
    BASHRC="$HOME/.bashrc"
    CONTENT=$(cat <<EOF
# Cargar aliases personales
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
EOF
)
    # Limpieza legacy
    sed -i '/source ~\/.bash_aliases/d' "$BASHRC"

    update_bashrc_block "ALIASES" "$CONTENT" "before-ble"
    
    configure_wsl_path
    ensure_path
}

# ─────────────────────────────────────────────────────────────
# Configura el PATH en WSL
# ─────────────────────────────────────────────────────────────
configure_wsl_path() {
    if [ ! -f /proc/version ] || ! grep -qi microsoft /proc/version; then
        return
    fi
    
    print_info "Detectado WSL. Limpiando PATH de Windows..."
    
    CONTENT=$(cat <<EOF
# WSL: Limpiar PATH de Windows (evitar conflictos con binarios .exe)
if grep -qi microsoft /proc/version 2>/dev/null; then
    NEW_PATH=\$(echo "\$PATH" | tr ":" "\n" | grep -v "^/mnt/" | tr "\n" ":" | sed "s/:\$//")
    export PATH="\$NEW_PATH"
fi
EOF
)
    update_bashrc_block "WSL_PATH" "$CONTENT" "top"
}

# ─────────────────────────────────────────────────────────────
# Path Universal
# ─────────────────────────────────────────────────────────────
ensure_path() {
    # Agregamos .local/bin para mise y tools
    CONTENT='export PATH="$HOME/.local/bin:$HOME/.atuin/bin:/usr/local/bin:$PATH"'
    update_bashrc_block "PATH_FIX" "$CONTENT" "before-ble"
}

# ─────────────────────────────────────────────────────────────
# Configura Google Antigravity (agy) en WSL.
# ─────────────────────────────────────────────────────────────
install_antigravity_fix() {
    if ! grep -qi microsoft /proc/version 2>/dev/null; then return; fi

    print_info "Configurando Google Antigravity (agy) para WSL..."
    
    WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tail -n1 | tr -d '\r')
    if [ -z "$WIN_USER" ] && [ -f "/mnt/c/Windows/System32/cmd.exe" ]; then
        WIN_USER=$(/mnt/c/Windows/System32/cmd.exe /c "echo %USERNAME%" 2>/dev/null | tail -n1 | tr -d '\r')
    fi
    
    if [ -n "$WIN_USER" ]; then
        AGY_PATH="/mnt/c/Users/$WIN_USER/AppData/Local/Programs/Antigravity/bin/antigravity"
        if [ -f "$AGY_PATH" ]; then
            mkdir -p "$HOME/.local/bin"
            rm -f "$HOME/.local/bin/agy"
            ln -s "$AGY_PATH" "$HOME/.local/bin/agy"
            print_success "Symlink 'agy' vinculado"
        fi
    fi
}

install_blesh() {
    print_step "Instalando Ble.sh (Bash Line Editor)..."
    BLESH_DIR="$HOME/.local/share/blesh"
    
    if [ ! -d "$BLESH_DIR" ]; then
         ensure_package "make"
         ensure_package "gawk"

         print_info "Clonando ble.sh..."
         rm -rf /tmp/ble.sh
         git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git /tmp/ble.sh
         make -C /tmp/ble.sh install PREFIX=~/.local
         rm -rf /tmp/ble.sh
    fi

    # Configuración .blerc
    cat > "$HOME/.blerc" <<'EOF'
_safe_bleopt() {
    local opt=$1 val=$2
    if bleopt "$opt" >/dev/null 2>&1; then bleopt "$opt=$val"; fi
}
ble-bind -f 'C-m' 'accept-line'
ble-bind -f 'RET' 'accept-line'
_safe_bleopt complete_auto_complete 1
_safe_bleopt complete_auto_history 1
_safe_bleopt complete_menu_style align-nowrap
_safe_bleopt exec_exit_status ""
_safe_bleopt print_exit_status 0
bleopt exec_elapsed_mark=
EOF

    # Configurar .bashrc
    BLE_SOURCE_CONTENT='# 1. Ble.sh Source
[[ $- == *i* && -f ~/.local/share/blesh/ble.sh ]] && source ~/.local/share/blesh/ble.sh --noattach 2>/dev/null'

    BLE_ATTACH_CONTENT='# 6. Ble.sh Attach
[[ ${BLE_VERSION-} ]] && ble-attach'

    update_bashrc_block "BLE_SOURCE" "$BLE_SOURCE_CONTENT" "top"
    update_bashrc_block "BLE_ATTACH" "$BLE_ATTACH_CONTENT" "bottom"
}

disable_blesh() {
    sed -i '/ble.sh/d' "$HOME/.bashrc"
    sed -i '/ble-attach/d' "$HOME/.bashrc"
    sed -i '/<!-- BEGIN_BLE_SOURCE -->/,/<!-- END_BLE_SOURCE -->/d' "$HOME/.bashrc"
    sed -i '/<!-- BEGIN_BLE_ATTACH -->/,/<!-- END_BLE_ATTACH -->/d' "$HOME/.bashrc"
    rm -rf "$HOME/.local/share/blesh" "$HOME/.cache/ble.sh"
}

configure_atuin() {
    print_step "Configurando Atuin..."
    # Config minimal check
    mkdir -p "$HOME/.config/atuin"
    
    # Atuin init se maneja vía eval, pero es mejor checkear si está instalado
    # ya que mise se encarga de instalarlo.
    if command -v atuin &> /dev/null; then
         # Opcional: Login si hay key en secrets
         if [ -n "$ATUIN_KEY" ]; then
             # Lógica de login automática (pendiente de implementar si se desea)
             :
         fi
         # Init script
         if ! grep -q "atuin init bash" "$HOME/.bashrc"; then
             CONTENT='eval "$(atuin init bash)"'
             update_bashrc_block "ATUIN" "$CONTENT" "before-ble"
         fi
    fi
}

configure_oh_my_posh() {
    print_step "Configurando Oh My Posh..."
    
    # Vincular tema local del repositorio
    mkdir -p "$HOME/.poshthemes"
    ln -sf "$DOTFILES_DIR/config/herwingx.omp.json" "$HOME/.poshthemes/herwingx.omp.json"

    CONTENT='eval "$(oh-my-posh init bash --config ~/.poshthemes/herwingx.omp.json)"'
    update_bashrc_block "OH_MY_POSH" "$CONTENT" "before-ble"
}
