#!/bin/bash
# ==============================================================================
# SYSTEM.SH - Base System Packages, Smart Update, Fonts & Shell Integrations
# Compatible with: Ubuntu/Debian & Fedora/RHEL (Server, Desktop & WSL)
# ==============================================================================

# ─────────────────────────────────────────────────────────────
# Genera y configura locales en_US.UTF-8 si faltan (común en LXC/Server)
# ─────────────────────────────────────────────────────────────
fix_locales() {
    if [ "$OS_TYPE" == "debian" ]; then
        if ! locale -a 2>/dev/null | grep -qi "en_US.utf8"; then
            print_warning "Locales UTF-8 faltantes. Generando en_US.UTF-8..."
            ensure_package "locales" "locale-gen"
            $SUDO_CMD locale-gen en_US.UTF-8
            $SUDO_CMD update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
            export LANG=en_US.UTF-8
            export LC_ALL=en_US.UTF-8
            print_success "Locales en_US.UTF-8 generados."
        fi
    elif [ "$OS_TYPE" == "redhat" ]; then
        if ! locale -a 2>/dev/null | grep -qi "en_US.utf8"; then
            ensure_package "glibc-langpack-en"
        fi
    fi
}

# ─────────────────────────────────────────────────────────────
# Actualiza el sistema operativo de forma inteligente (Caché 24h)
# @param $1 - Opcional: "--force" para ignorar el caché de 24h.
# ─────────────────────────────────────────────────────────────
update_system() {
    local force_update=false
    if [ "${1:-}" == "--force" ]; then
        force_update=true
    fi

    local state_file="$HOME/.local/state/dotfiles/last_update"
    mkdir -p "$(dirname "$state_file")"

    if [ -f "$state_file" ] && [ "$force_update" != "true" ]; then
        local last_update now diff
        last_update=$(cat "$state_file" 2>/dev/null || echo 0)
        now=$(date +%s)
        diff=$((now - last_update))

        if [ "$diff" -lt 86400 ]; then
            print_info "Smart Update: Sistema actualizado hace $((diff / 3600))h (usa --force para forzar)."
            return 0
        fi
    fi

    print_header "SYSTEM UPDATE :: ${OS_PRETTY_NAME}"
    fix_locales

    print_step "Sincronizando repositorios ($PKG_MANAGER)..."
    run_pkg_index_update

    print_step "Actualizando paquetes del sistema..."
    if [ "$OS_TYPE" == "debian" ]; then
        $SUDO_CMD env DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
        $SUDO_CMD env DEBIAN_FRONTEND=noninteractive apt-get autoremove -y
    elif [ "$OS_TYPE" == "redhat" ]; then
        $SUDO_CMD dnf upgrade -y
        $SUDO_CMD dnf autoremove -y
    fi

    date +%s > "$state_file"
    print_success "Sistema operativo actualizado."
}

# ─────────────────────────────────────────────────────────────
# Instala JetBrainsMono Nerd Font en entornos Desktop (Ubuntu/Fedora)
# para que Oh My Posh y lsd muestren iconos perfectamente.
# ─────────────────────────────────────────────────────────────
install_nerd_font() {
    if [ "$IS_DESKTOP" != "true" ]; then
        return 0
    fi

    local font_dir="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
    if [ -d "$font_dir" ] && [ -n "$(ls -A "$font_dir" 2>/dev/null)" ]; then
        print_info "JetBrainsMono Nerd Font ya instalada."
        return 0
    fi

    print_step "Instalando JetBrainsMono Nerd Font (Desktop)..."
    mkdir -p "$font_dir"
    local tmp_archive
    tmp_archive=$(mktemp --suffix=.tar.xz)

    if curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" -o "$tmp_archive"; then
        tar -xf "$tmp_archive" -C "$font_dir" 2>/dev/null || true
        rm -f "$tmp_archive"
        if command -v fc-cache &>/dev/null; then
            fc-cache -f "$font_dir" >/dev/null 2>&1 || true
        fi
        print_success "JetBrainsMono Nerd Font instalada en $font_dir"
    else
        rm -f "$tmp_archive"
        print_warning "No se pudo descargar JetBrainsMono Nerd Font (no crítico)."
    fi
}

# ─────────────────────────────────────────────────────────────
# Instala paquetes base del sistema de forma idempotente
# Distingue automáticamente entre Server (headless) y Desktop.
# ─────────────────────────────────────────────────────────────
install_packages() {
    print_header "BASE PACKAGES & SHELL SETUP (${ENV_PROFILE^^})"

    # Paquetes esenciales comunes (nombre_paquete:binario_en_path)
    local common_specs=(
        "git:git"
        "curl:curl"
        "wget:wget"
        "unzip:unzip"
        "tar:tar"
        "tree:tree"
        "tmux:tmux"
        "ranger:ranger"
        "mc:mc"
        "make:make"
        "jq:jq"
        "file:file"
        "net-tools:netstat"
    )

    for spec in "${common_specs[@]}"; do
        local pkg="${spec%%:*}"
        local bin="${spec##*:}"
        ensure_package "$pkg" "$bin"
    done

    # Paquetes específicos por familia de distribución (Ubuntu/Debian vs Fedora/RHEL)
    case "$OS_TYPE" in
        debian)
            ensure_package "ca-certificates" "update-ca-certificates"
            ensure_package "gnupg" "gpg"
            ensure_package "build-essential" "gcc"
            ensure_package "dnsutils" "dig"
            ensure_package "procps" "ps"
            ;;
        redhat)
            ensure_package "ca-certificates" "update-ca-trust"
            ensure_package "gnupg2" "gpg"
            ensure_package "gcc" "gcc"
            ensure_package "gcc-c++" "g++"
            ensure_package "xz" "xz"
            ensure_package "bind-utils" "dig"
            ensure_package "procps-ng" "ps"
            ensure_package "findutils" "find"
            ;;
    esac

    # Herramientas de portapapeles y fuentes solo en Desktop (evita instalar X11 en Server)
    if [ "$IS_DESKTOP" == "true" ]; then
        if [ "$SESSION_DISPLAY_TYPE" == "wayland" ]; then
            ensure_package "wl-clipboard" "wl-copy"
        fi
        ensure_package "xclip" "xclip"
        install_nerd_font
    fi

    # Configurar ranger si está instalado
    if command -v ranger &> /dev/null && [ ! -d "$HOME/.config/ranger" ]; then
        print_info "Inicializando configuración de ranger..."
        ranger --copy-config=all >/dev/null 2>&1 || true
    fi

    # Vincular configuración de Tmux
    if [ -f "$DOTFILES_DIR/config/.tmux.conf" ]; then
        ln -sf "$DOTFILES_DIR/config/.tmux.conf" "$HOME/.tmux.conf"
        print_success "Tmux configurado (~/.tmux.conf)."
    fi

    install_bash_aliases
    configure_fzf
    configure_zoxide
    configure_oh_my_posh

    print_success "Paquetes base y configuración de shell completados."
}

# ─────────────────────────────────────────────────────────────
# Vincula .bash_aliases y configura bloques limpios en .bashrc
# ─────────────────────────────────────────────────────────────
install_bash_aliases() {
    print_step "Vinculando Bash Aliases y variables de entorno..."
    local alias_file="$HOME/.bash_aliases"
    if [ -f "$alias_file" ] && [ ! -L "$alias_file" ]; then
        mv "$alias_file" "$alias_file.backup"
    fi
    ln -sf "$DOTFILES_DIR/config/.bash_aliases" "$alias_file"

    local bashrc="$HOME/.bashrc"
    [ -f "$bashrc" ] || touch "$bashrc"
    sed -i '/source ~\/.bash_aliases/d' "$bashrc"

    local content='# Cargar aliases personales
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi'
    update_bashrc_block "ALIASES" "$content" "bottom"

    configure_wsl_path
    ensure_path
}

# ─────────────────────────────────────────────────────────────
# En WSL, limpia las rutas /mnt/c del PATH para evitar colisiones
# ─────────────────────────────────────────────────────────────
configure_wsl_path() {
    if [ "$IS_WSL" != "true" ]; then
        return 0
    fi

    print_info "Entorno WSL detectado: aislando PATH de binarios .exe de Windows..."
    local content='# WSL: Limpiar PATH de Windows (evitar conflictos con binarios .exe)
if grep -qi microsoft /proc/version 2>/dev/null; then
    NEW_PATH=$(echo "$PATH" | tr ":" "\n" | grep -v "^/mnt/" | awk "!seen[\$0]++" | paste -sd: -)
    export PATH="$NEW_PATH"
fi'
    update_bashrc_block "WSL_PATH" "$content" "bottom"
}

# ─────────────────────────────────────────────────────────────
# Configura el PATH universal sin entradas duplicadas y Proton Pass
# ─────────────────────────────────────────────────────────────
ensure_path() {
    local content='# Deduplicated PATH & Proton Pass CLI persistence
export PROTON_PASS_KEY_PROVIDER="${PROTON_PASS_KEY_PROVIDER:-fs}"
for _dir in "$HOME/.local/share/mise/shims" "$HOME/.local/bin" "$HOME/bin" "/usr/local/bin"; do
    if [ -d "$_dir" ] && [[ ":$PATH:" != *":$_dir:"* ]]; then
        export PATH="$_dir:$PATH"
    fi
done
unset _dir'
    update_bashrc_block "PATH_FIX" "$content" "bottom"
}

# ─────────────────────────────────────────────────────────────
# Configura integración de fzf con Bash (Ctrl+R historial, Ctrl+T archivos)
# ─────────────────────────────────────────────────────────────
configure_fzf() {
    print_step "Configurando fzf keybindings en .bashrc..."
    local content='# fzf - Búsqueda fuzzy en historial (Ctrl+R), archivos (Ctrl+T) y directorios (Alt+C)
if command -v fzf &>/dev/null; then
    eval "$(fzf --bash)"
fi'
    update_bashrc_block "FZF" "$content" "bottom"
}

# ─────────────────────────────────────────────────────────────
# Configura integración de zoxide (reemplazo inteligente de cd)
# ─────────────────────────────────────────────────────────────
configure_zoxide() {
    print_step "Configurando zoxide en .bashrc..."
    local content='# zoxide - Navegación inteligente de directorios (z / zi)
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
fi'
    update_bashrc_block "ZOXIDE" "$content" "bottom"
}

# ─────────────────────────────────────────────────────────────
# Configura Oh My Posh con el tema del repositorio
# ─────────────────────────────────────────────────────────────
configure_oh_my_posh() {
    print_step "Configurando Oh My Posh..."
    mkdir -p "$HOME/.poshthemes"
    ln -sf "$DOTFILES_DIR/config/herwingx.omp.json" "$HOME/.poshthemes/herwingx.omp.json"

    local content='# Oh My Posh Prompt
if command -v oh-my-posh &>/dev/null; then
    eval "$(oh-my-posh init bash --config ~/.poshthemes/herwingx.omp.json)"
fi'
    update_bashrc_block "OH_MY_POSH" "$content" "bottom"
}
