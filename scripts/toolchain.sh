#!/bin/bash
# ==========================================
# TOOLCHAIN - Gestión de Herramientas (Mise)
# ==========================================
# Instala y configura mise como gestor de versiones universal
# Incluye migración inteligente desde herramientas legacy (NVM, etc.)
# ==========================================

# ─────────────────────────────────────────────────────────────
# Detecta y desactiva herramientas que entran en conflicto con Mise
#
# Evita colisiones de comandos detectando sistemas de versiones
# legacy como NVM o binarios individuales instalados localmente.
# Renombra directorios en lugar de borrarlos para preservar datos.
#
# @sideeffects Renombra carpetas e invalida paths previos en .bashrc.
# ─────────────────────────────────────────────────────────────
cleanup_legacy_conflicts() {
    print_step "Checking for legacy tool conflicts..."
    
    local conflicts_found=false
    
    # 1. Detectar NVM (Node Version Manager)
    if [ -d "$HOME/.nvm" ] || grep -q "NVM_DIR" "$HOME/.bashrc"; then
        print_warning "Legacy NVM detected. It conflicts with Mise."
        conflicts_found=true
        
        # Desactivar de .bashrc
        sed -i '/export NVM_DIR/d' "$HOME/.bashrc"
        sed -i '/\[ -s "$NVM_DIR\/nvm.sh" \]/d' "$HOME/.bashrc"
        sed -i '/\[ -s "$NVM_DIR\/bash_completion" \]/d' "$HOME/.bashrc"
        
        # Renombrar directorio para desactivar (Backup seguro)
        if [ -d "$HOME/.nvm" ]; then
            mv "$HOME/.nvm" "$HOME/.nvm.backup_legacy"
            print_success "NVM disabled (backed up to ~/.nvm.backup_legacy)"
        fi
    fi
    
    # 2. Detectar Go legacy en /usr/local/go
    if [ -d "/usr/local/go" ]; then
        print_warning "System-wide Go detected in /usr/local/go."
        print_info "Mise will manage Go user-locally. Consider removing /usr/local/go later."
    fi
    
    # 3. Limpiar binarios manuales antiguos que ahora maneja Mise
    local legacy_bins=("lsd" "bat" "rg" "fd" "zoxide")
    for bin in "${legacy_bins[@]}"; do
        if [ -f "$HOME/.local/bin/$bin" ]; then
            # Solo si NO es un shim de mise
            if ! grep -q "mise" "$HOME/.local/bin/$bin"; then
                mv "$HOME/.local/bin/$bin" "$HOME/.local/bin/$bin.old"
                print_info "Archived legacy binary: $bin -> $bin.old"
            fi
        fi
    done

    if [ "$conflicts_found" = false ]; then
        print_success "No critical conflicts found."
    fi
}

# ─────────────────────────────────────────────────────────────
# Instala y sincroniza el Toolchain vía Mise
#
# Descarga el instalador de Mise, lo añade a .bashrc e instala
# automáticamente todas las herramientas declaradas en .mise.toml
# (Node, Go, Rust, etc.).
#
# @sideeffects Ejecuta el script remoto de mise.run e instala binarios locales.
# ─────────────────────────────────────────────────────────────
install_toolchain() {
    print_header "TOOLCHAIN SETUP (MISE)"
    
    # 0. Limpieza preventiva
    cleanup_legacy_conflicts
    
    # 1. Instalar mise si no existe
    if ! command -v mise &> /dev/null; then
        print_step "Installing mise (CLI version manager)..."
        ensure_package "curl" # Ensure curl is present
        curl https://mise.run | sh
        
        # Añadir al path temporalmente para esta sesión
        export PATH="$HOME/.local/bin:$PATH"
    else
        print_info "mise is already installed."
    fi

    # 2. Configurar activación en .bashrc
    local config_block='eval "$(mise activate bash)"'

    if declare -f update_bashrc_block > /dev/null; then
        update_bashrc_block "MISE" "$config_block" "bottom"
    else
        if ! grep -q "mise activate bash" "$HOME/.bashrc"; then
            echo "" >> "$HOME/.bashrc"
            echo "$config_block" >> "$HOME/.bashrc"
        fi
    fi

    # 3. Instalar herramientas declaradas en .mise.toml
    if [ -f "$DOTFILES_DIR/.mise.toml" ]; then
        print_step "Syncing tools from .mise.toml..."
        
        # Confiar en el archivo de configuración local para evitar prompts
        mise trust "$DOTFILES_DIR/.mise.toml"
        mise trust "$HOME/.mise.toml" 2>/dev/null
        
        # Linking global config if desired
        ln -sf "$DOTFILES_DIR/.mise.toml" "$HOME/.mise.toml"
        
        # Instalar
        mise install -y
        
        if [ $? -eq 0 ]; then
            print_success "Toolchain synced (Node, Go, Rust, etc.)"
            mise list
        else
            print_error "Failed to install some mise tools."
        fi
    else
        print_warning ".mise.toml not found in $DOTFILES_DIR"
    fi
    
    # 4. Activar para el resto del script
    eval "$(mise activate bash)"
}
