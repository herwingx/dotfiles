#!/bin/bash
# ==========================================
# TOOLCHAIN - Gestión de Herramientas (Mise)
# ==========================================
# Instala y configura mise como gestor de versiones universal
# ==========================================

install_toolchain() {
    print_header "TOOLCHAIN SETUP (MISE)"
    
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
    local config_block='# Mise (Version Manager)
export PATH="$HOME/.local/bin:$PATH"
eval "$(mise activate bash)"'

    # Intentar usar helper de system.sh si está disponible (cargado via install.sh)
    if declare -f update_bashrc_block > /dev/null; then
        update_bashrc_block "MISE" "$config_block" "top"
    else
        # Fallback manual si se ejecuta standalone
        if ! grep -q "mise activate bash" "$HOME/.bashrc"; then
            echo "" >> "$HOME/.bashrc"
            echo "$config_block" >> "$HOME/.bashrc"
        fi
    fi

    # 3. Instalar herramientas declaradas en .mise.toml
    if [ -f "$DOTFILES_DIR/.mise.toml" ]; then
        print_step "Syncing tools from .mise.toml..."
        
        # Linking global config if desired, or just installing from repo root
        # Mise picks up .mise.toml in current dir or parent dirs.
        # We link it to ~/.config/mise/config.toml or ~/.mise.toml for global usage.
        
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
