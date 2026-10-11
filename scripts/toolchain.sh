#!/bin/bash
# ==============================================================================
# TOOLCHAIN.SH - Declarative Toolchain (Mise + Proton Pass CLI)
# Gestiona Node, pnpm, Bun, Go, Rust, Python, uv y utilidades CLI modernas.
# ==============================================================================

# ─────────────────────────────────────────────────────────────
# Detecta y archiva herramientas legacy que colisionan con Mise
# ─────────────────────────────────────────────────────────────
cleanup_legacy_conflicts() {
    print_step "Verificando conflictos con herramientas legacy..."

    local conflicts_found=false

    # 1. Detectar NVM (Node Version Manager)
    if [ -d "$HOME/.nvm" ] || grep -q "NVM_DIR" "$HOME/.bashrc" 2>/dev/null; then
        print_warning "Legacy NVM detectado. Desactivando en favor de Mise..."
        conflicts_found=true

        sed -i '/export NVM_DIR/d' "$HOME/.bashrc" 2>/dev/null
        sed -i '/\[ -s "$NVM_DIR\/nvm.sh" \]/d' "$HOME/.bashrc" 2>/dev/null
        sed -i '/\[ -s "$NVM_DIR\/bash_completion" \]/d' "$HOME/.bashrc" 2>/dev/null

        if [ -d "$HOME/.nvm" ]; then
            mv "$HOME/.nvm" "$HOME/.nvm.backup_legacy"
            print_success "NVM respaldado en ~/.nvm.backup_legacy"
        fi
    fi

    # 2. Limpiar binarios manuales antiguos que ahora maneja Mise
    local legacy_bins=("lsd" "bat" "rg" "fd" "zoxide" "lazygit" "gum")
    for bin in "${legacy_bins[@]}"; do
        if [ -f "$HOME/.local/bin/$bin" ]; then
            if ! grep -q "mise" "$HOME/.local/bin/$bin" 2>/dev/null; then
                mv "$HOME/.local/bin/$bin" "$HOME/.local/bin/$bin.old"
                print_info "Binario manual archivado: $bin -> $bin.old"
            fi
        fi
    done

    if [ "$conflicts_found" = false ]; then
        print_success "Sin conflictos legacy detectados."
    fi
}

# ─────────────────────────────────────────────────────────────
# Añade PATH deduplicado y shims de Mise a perfiles de login
# (.profile, .bash_profile, .zprofile) para IDEs (VS Code / Cursor)
# ─────────────────────────────────────────────────────────────
ensure_profile_mise() {
    local block='# BEGIN_MISE_PROFILE
export PROTON_PASS_KEY_PROVIDER="${PROTON_PASS_KEY_PROVIDER:-fs}"
for _dir in "$HOME/.local/share/mise/shims" "$HOME/.local/bin" "$HOME/bin" "/usr/local/bin"; do
    if [ -d "$_dir" ] && [ "${PATH#*$_dir}" = "$PATH" ]; then
        export PATH="$_dir:$PATH"
    fi
done
unset _dir
# END_MISE_PROFILE'

    local profile="$HOME/.profile"
    [ -f "$profile" ] || touch "$profile"
    sed -i "/# BEGIN_MISE_PROFILE/,/# END_MISE_PROFILE/d" "$profile" 2>/dev/null
    printf "\n%s\n" "$block" >> "$profile"

    if [ -f "$HOME/.bash_profile" ]; then
        sed -i "/# BEGIN_MISE_PROFILE/,/# END_MISE_PROFILE/d" "$HOME/.bash_profile" 2>/dev/null
        printf "\n%s\n" "$block" >> "$HOME/.bash_profile"
    fi

    local zprofile="$HOME/.zprofile"
    [ -f "$zprofile" ] || touch "$zprofile"
    sed -i "/# BEGIN_MISE_PROFILE/,/# END_MISE_PROFILE/d" "$zprofile" 2>/dev/null
    printf "\n%s\n" "$block" >> "$zprofile"

    print_success "Perfiles de login (.profile / .zprofile) configurados con Mise shims."
}

# ─────────────────────────────────────────────────────────────
# Instala Mise, Proton Pass CLI y sincroniza .mise.toml
# Funciona con o sin credenciales de GitHub en distros limpias.
# ─────────────────────────────────────────────────────────────
install_toolchain() {
    print_header "TOOLCHAIN SETUP (MISE + PROTON PASS CLI)"

    cleanup_legacy_conflicts

    # 1. Instalar mise si no existe
    if ! command -v mise &> /dev/null; then
        print_step "Instalando Mise (gestor de runtimes y herramientas)..."
        ensure_package "curl"
        curl -fsSL https://mise.run | sh
        path_prepend "$HOME/.local/bin"
    else
        print_info "Mise ya está instalado ($(mise --version 2>/dev/null | head -1))."
    fi

    # 2. Instalar Proton Pass CLI (pass-cli)
    ensure_pass_cli

    # 3. Configurar activación en .bashrc (shims al inicio + activate al final)
    local shims_block='if [ -d "$HOME/.local/share/mise/shims" ] && [[ ":$PATH:" != *":$HOME/.local/share/mise/shims:"* ]]; then
    export PATH="$HOME/.local/share/mise/shims:$PATH"
fi'
    local config_block='if command -v mise &>/dev/null; then
    eval "$(mise activate bash)"
fi'

    update_bashrc_block "MISE_SHIMS" "$shims_block" "top"
    update_bashrc_block "MISE" "$config_block" "bottom"
    ensure_profile_mise

    # 4. Sincronizar herramientas declaradas en .mise.toml
    if [ -f "$DOTFILES_DIR/.mise.toml" ]; then
        print_step "Sincronizando herramientas desde .mise.toml..."

        mkdir -p "$HOME/.config/mise"
        ln -sf "$DOTFILES_DIR/.mise.toml" "$HOME/.mise.toml"
        ln -sf "$DOTFILES_DIR/.mise.toml" "$HOME/.config/mise/config.toml"

        mise trust "$DOTFILES_DIR/.mise.toml" 2>/dev/null || true
        mise trust "$HOME/.mise.toml" 2>/dev/null || true
        mise trust "$HOME/.config/mise/config.toml" 2>/dev/null || true

        # Si hay token de GitHub disponible (en env o gh CLI), pasarlo a mise
        # para evitar rate-limits de GitHub API; si no hay (distro nueva), continúa normal.
        if [ -z "${GITHUB_TOKEN:-}" ]; then
            if [ -n "${GH_TOKEN:-}" ]; then
                export GITHUB_TOKEN="$GH_TOKEN"
            elif command -v gh &>/dev/null && gh auth status &>/dev/null; then
                GITHUB_TOKEN="$(gh auth token 2>/dev/null || true)"
                [ -n "$GITHUB_TOKEN" ] && export GITHUB_TOKEN
            fi
        fi

        if mise install -y; then
            print_success "Toolchain Web & CLI sincronizado con éxito."
            path_prepend "$HOME/.local/share/mise/shims"
            mise list
        else
            print_warning "Algunas herramientas de Mise reportaron advertencias. Puedes reintentar con 'mise install'."
        fi
    else
        print_warning "No se encontró .mise.toml en $DOTFILES_DIR"
    fi

    if command -v mise &>/dev/null; then
        eval "$(mise activate bash)"
    fi
}
