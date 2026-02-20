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
    
    # Ble.sh ELIMINADO por solicitud (conflicto con VSCode)
    
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

configure_atuin() {
    print_step "Configurando Atuin..."

    mkdir -p "$HOME/.config/atuin"

    # Vincular configuración desde el repositorio
    ln -sf "$DOTFILES_DIR/config/atuin.toml" "$HOME/.config/atuin/config.toml"

    if command -v atuin &> /dev/null; then
         # Opcional: Login si hay key en secrets
         if [ -n "$ATUIN_KEY" ]; then
             # Lógica de login automática (pendiente de implementar si se desea)
             :
         fi
         # Atuin DEBE cargarse al final del .bashrc para no perder sus hooks de PROMPT_COMMAND
         # (otros tools como oh-my-posh también modifican PROMPT_COMMAND)
         # Además incluye workaround para VS Code WSL Remote que sobreescribe el DEBUG trap.
         if ! grep -q "atuin init bash" "$HOME/.bashrc"; then
             CONTENT='# Atuin debe cargarse al final para preservar sus hooks de PROMPT_COMMAND
if [ -f "$HOME/.atuin/bin/env" ]; then
    . "$HOME/.atuin/bin/env"
fi
if command -v atuin &>/dev/null; then
    eval "$(atuin init bash)"
    # Workaround: VS Code WSL Remote reemplaza el DEBUG trap de Atuin al inyectar
    # su shell integration DESPUÉS de .bashrc. Este helper lo restaura en cada prompt.
    __atuin_restore_trap() {
        if [[ "$(trap -p DEBUG 2>/dev/null)" != *"__atuin_preexec"* ]]; then
            trap -- '"'"'__vsc_preexec_only "$_"; __atuin_preexec "$_"'"'"' DEBUG 2>/dev/null || \
            trap -- '"'"'__atuin_preexec "$_"'"'"' DEBUG 2>/dev/null || true
        fi
    }
    PROMPT_COMMAND="__atuin_restore_trap;${PROMPT_COMMAND}"
fi'
             update_bashrc_block "ATUIN" "$CONTENT" "bottom"
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
