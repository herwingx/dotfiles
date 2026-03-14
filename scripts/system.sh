#!/bin/bash
# ==========================================
# SYSTEM - Actualización y paquetes del sistema
# ==========================================
# Funciones para actualizar el sistema operativo e instalar
# paquetes base mediante ensure_package (idempotente).
# ==========================================

# ─────────────────────────────────────────────────────────────
# Fix locales en Debian/Ubuntu
#
# Genera y configura los locales en_US.UTF-8 si faltan,
# algo común en instalaciones mínimas o contenedores.
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

# ─────────────────────────────────────────────────────────────
# Actualiza el sistema operativo de forma inteligente
#
# Evita actualizaciones repetitivas guardando la última fecha
# de actualización. Si han pasado menos de 24 horas, la omite.
#
# @param $1 - Opcional: "--force" para ignorar el límite de 24h.
# ─────────────────────────────────────────────────────────────
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
    elif [ "$OS_TYPE" == "suse" ]; then
        $SUDO_CMD zypper up -y
    elif [ "$OS_TYPE" == "alpine" ]; then
        $SUDO_CMD apk upgrade
    fi
    
    # Guardar timestamp
    date +%s > "$UPDATE_STATE_FILE"
    
    print_success "Sistema actualizado"
}

# ─────────────────────────────────────────────────────────────
# Instala paquetes base del sistema
#
# Utiliza `ensure_package` de manera idempotente para instalar
# dependencias clave dependiendo de la distribución detectada.
#
# @sideeffects Configura alias, bashrc, PATH y gestores de terminal.
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
        suse)
            PACKAGES+=("gcc" "bind-utils" "age")
            $SUDO_CMD zypper install -y -t pattern devel_basis 2>/dev/null
            ;;
        alpine)
            PACKAGES+=("alpine-sdk" "bind-tools" "age")
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
    
    # Oh My Posh se gestiona via Mise (toolchain.sh)
    configure_fzf
    configure_oh_my_posh
    
    # Tmux Configuration
    if [ -f "$DOTFILES_DIR/config/.tmux.conf" ]; then
        ln -sf "$DOTFILES_DIR/config/.tmux.conf" "$HOME/.tmux.conf"
    fi
}

# ─────────────────────────────────────────────────────────────
# Vincula y configura el archivo .bash_aliases
#
# Crea un enlace simbólico desde config/.bash_aliases al home,
# y añade la lógica a .bashrc para cargarlo automáticamente.
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

    update_bashrc_block "ALIASES" "$CONTENT" "bottom"
    
    configure_wsl_path
    ensure_path
}

# ─────────────────────────────────────────────────────────────
# Configura el PATH en WSL
#
# Elimina las rutas montadas de Windows (/mnt/c/...) del PATH de Linux
# para evitar colisiones entre binarios (.exe) y comandos nativos.
# Solo se ejecuta en entornos Windows Subsystem for Linux (WSL).
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
    update_bashrc_block "WSL_PATH" "$CONTENT" "bottom"
}

# ─────────────────────────────────────────────────────────────
# Configuración del PATH Universal
#
# Añade `~/.local/bin` y otras rutas clave al inicio del PATH
# para priorizar las herramientas locales instaladas.
# ─────────────────────────────────────────────────────────────
ensure_path() {
    # Agregamos .local/bin para mise y tools
    CONTENT='export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"'
    update_bashrc_block "PATH_FIX" "$CONTENT" "bottom"
}

# ─────────────────────────────────────────────────────────────
# Configura la integración de fzf con Bash
#
# Añade atajos útiles como Ctrl+R (historial) o Ctrl+T (archivos).
# ─────────────────────────────────────────────────────────────
configure_fzf() {
    print_step "Configurando fzf..."
    if command -v fzf &>/dev/null; then
        if ! grep -q "fzf --bash" "$HOME/.bashrc"; then
            CONTENT='# fzf - Búsqueda fuzzy en historial (Ctrl+R), archivos (Ctrl+T) y directorios (Alt+C)
if command -v fzf &>/dev/null; then
    eval "$(fzf --bash)"
fi'
            update_bashrc_block "FZF" "$CONTENT" "bottom"
        fi
    fi
}

# ─────────────────────────────────────────────────────────────
# Configura Oh My Posh
#
# Enlaza el tema personalizado del repositorio y añade
# el bloque de inicialización de OMP en .bashrc.
# ─────────────────────────────────────────────────────────────
configure_oh_my_posh() {
    print_step "Configurando Oh My Posh..."
    
    # Vincular tema local del repositorio
    mkdir -p "$HOME/.poshthemes"
    ln -sf "$DOTFILES_DIR/config/herwingx.omp.json" "$HOME/.poshthemes/herwingx.omp.json"

    CONTENT='eval "$(oh-my-posh init bash --config ~/.poshthemes/herwingx.omp.json)"'
    update_bashrc_block "OH_MY_POSH" "$CONTENT" "bottom"
}
