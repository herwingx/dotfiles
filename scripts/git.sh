#!/bin/bash
# ==============================================================================
# GIT.SH - Configuración de Git, Delta y Gestión de Llaves SSH (Proton Pass/GitHub)
# ==============================================================================

# ─────────────────────────────────────────────────────────────
# Configura Git globalmente de forma segura para Server y Desktop
# No fuerza git@github.com: si no hay llave SSH, evitando romper
# clones HTTPS en distros recién instaladas.
# ─────────────────────────────────────────────────────────────
install_gitconfig() {
    print_step "Configurando Git (~/.gitconfig)..."
    cp "$DOTFILES_DIR/config/.gitconfig" "$HOME/.gitconfig"

    # Si delta está disponible, activarlo como pager de Git
    if command -v delta &>/dev/null; then
        git config --global core.pager "delta"
    fi

    # En servidores headless (sin VS Code), usar nano/vim como editor por defecto de Git
    if [ "$IS_SERVER" == "true" ] && ! detect_editor &>/dev/null; then
        git config --global core.editor "${EDITOR:-nano}"
    fi

    # Si gh CLI está autenticado, delegar credenciales HTTPS a gh
    if command -v gh &>/dev/null && (unset GH_TOKEN GITHUB_TOKEN; gh auth status &>/dev/null); then
        (unset GH_TOKEN GITHUB_TOKEN; gh auth setup-git 2>/dev/null || true)
    elif [ "$IS_WSL" != "true" ]; then
        git config --global credential.helper store
    fi

    print_success "Git configurado correctamente."
}

# ─────────────────────────────────────────────────────────────
# Importa llaves públicas de GitHub a authorized_keys, carga llaves
# de Proton Pass y genera ~/.ssh/id_ed25519 automáticamente si no existe.
# ─────────────────────────────────────────────────────────────
install_ssh_keys() {
    print_step "Configurando directorio ~/.ssh y llaves autorizadas..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    touch "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys"

    local tmp_keys
    tmp_keys=$(mktemp)
    if curl -fsSL "https://github.com/herwingx.keys" -o "$tmp_keys" 2>/dev/null && [ -s "$tmp_keys" ]; then
        local added=0
        while IFS= read -r key_line || [ -n "$key_line" ]; do
            [ -z "$key_line" ] && continue
            if ! grep -qxF "$key_line" "$HOME/.ssh/authorized_keys" 2>/dev/null; then
                echo "$key_line" >> "$HOME/.ssh/authorized_keys"
                added=$((added + 1))
            fi
        done < "$tmp_keys"
        print_success "Llaves públicas autorizadas de herwingx verificadas ($added nuevas añadidas)."
    else
        print_warning "No se pudieron descargar llaves desde github.com/herwingx.keys (sin red o vacías)."
    fi
    rm -f "$tmp_keys"

    # Si no existe llave SSH Ed25519 local en esta máquina, crearla automáticamente
    local key_file="$HOME/.ssh/id_ed25519"
    if [ ! -f "$key_file" ]; then
        local email
        email=$(git config --global user.email 2>/dev/null || echo "developer@herwingx.com")
        print_step "Generando nueva llave SSH Ed25519 en $key_file ($email)..."
        ssh-keygen -t ed25519 -C "$email" -f "$key_file" -N "" >/dev/null 2>&1
        chmod 600 "$key_file"
        chmod 644 "$key_file.pub"
        print_success "Llave SSH Ed25519 creada automáticamente en $key_file"
    else
        print_info "Llave SSH Ed25519 local detectada en $key_file"
    fi

    # Iniciar ssh-agent y registrar la llave Ed25519 local
    if [ -z "${SSH_AUTH_SOCK:-}" ]; then
        eval "$(ssh-agent -s)" >/dev/null 2>&1
    fi
    if [ -f "$key_file" ]; then
        ssh-add -l 2>/dev/null | grep -q "id_ed25519" || ssh-add "$key_file" 2>/dev/null || true
    fi

    # Si Proton Pass CLI tiene sesión activa, cargar también llaves SSH del vault al ssh-agent
    if pass_is_logged_in; then
        print_step "Cargando llaves SSH almacenadas en Proton Pass..."
        pass-cli ssh-agent load 2>/dev/null || true
    fi
}

# ─────────────────────────────────────────────────────────────
# Importa llaves SSH desde Windows (Solo WSL)
# ─────────────────────────────────────────────────────────────
copy_ssh_from_windows() {
    print_step "Copiando llaves SSH desde Windows a WSL..."

    if [ "$IS_WSL" != "true" ] && [ ! -d "/mnt/c" ]; then
        print_error "No se detectó WSL. Esta opción solo aplica en entornos WSL."
        return 1
    fi

    local win_user=""
    if command -v cmd.exe &>/dev/null; then
        win_user=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
    fi
    if [ -z "$win_user" ] || [ "$win_user" = "%USERNAME%" ]; then
        win_user=$(find /mnt/c/Users -maxdepth 1 -mindepth 1 -type d 2>/dev/null | grep -vE "/(Public|Default|Default User|All Users)$" | head -1 | xargs -r basename)
    fi

    if [ -z "$win_user" ]; then
        win_user=$(ui_input "Nombre de usuario de Windows" "")
    fi

    local win_ssh_dir="/mnt/c/Users/$win_user/.ssh"
    if [ ! -d "$win_ssh_dir" ]; then
        print_error "No se encontró el directorio: $win_ssh_dir"
        return 1
    fi

    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    local keys_copied=0
    for key_type in id_ed25519 id_rsa id_ecdsa; do
        if [ -f "$win_ssh_dir/$key_type" ]; then
            cp "$win_ssh_dir/$key_type" "$HOME/.ssh/"
            chmod 600 "$HOME/.ssh/$key_type"
            print_success "Copiada llave privada: $key_type"
            keys_copied=$((keys_copied + 1))
        fi
        if [ -f "$win_ssh_dir/$key_type.pub" ]; then
            cp "$win_ssh_dir/$key_type.pub" "$HOME/.ssh/"
            chmod 644 "$HOME/.ssh/$key_type.pub"
        fi
    done

    [ -f "$win_ssh_dir/config" ] && cp "$win_ssh_dir/config" "$HOME/.ssh/" && chmod 600 "$HOME/.ssh/config"
    [ -f "$win_ssh_dir/known_hosts" ] && cp "$win_ssh_dir/known_hosts" "$HOME/.ssh/" && chmod 600 "$HOME/.ssh/known_hosts"

    if [ $keys_copied -eq 0 ]; then
        print_warning "No se encontraron llaves privadas en $win_ssh_dir"
        return 1
    fi

    print_success "$keys_copied llave(s) SSH importadas desde Windows."
    return 0
}

# ─────────────────────────────────────────────────────────────
# Sube la llave ~/.ssh/id_ed25519 actual a Proton Pass y/o GitHub
# ─────────────────────────────────────────────────────────────
backup_ssh_key_to_cloud() {
    local key_file="$HOME/.ssh/id_ed25519"
    if [ ! -f "$key_file" ]; then
        print_warning "No existe $key_file todavía. Generando una nueva..."
        generate_ssh_key_interactive || return 1
        return 0
    fi

    load_pass_config
    local default_title="SSH-$(hostname -s)"

    if pass_is_logged_in && ui_confirm "¿Deseas guardar esta llave privada Ed25519 en tu bóveda '$PROTON_PASS_VAULT' de Proton Pass?"; then
        local title
        title=$(ui_input "Nombre para guardar la llave en Proton Pass" "$default_title")
        title="${title:-$default_title}"
        if pass-cli item create ssh-key import \
            --vault-name "$PROTON_PASS_VAULT" \
            --from-private-key "$key_file" \
            --title "$title"; then
            print_success "Llave SSH '$title' guardada en Proton Pass."
        fi
    fi

    if command -v gh &>/dev/null && (unset GH_TOKEN GITHUB_TOKEN; gh auth status &>/dev/null); then
        if ui_confirm "¿Deseas registrar la llave pública ($key_file.pub) en tu cuenta de GitHub?"; then
            (unset GH_TOKEN GITHUB_TOKEN; gh ssh-key add "$key_file.pub" --title "$default_title" 2>/dev/null) \
                && print_success "Llave pública añadida a tu cuenta de GitHub ($default_title)." \
                || print_info "La llave ya estaba registrada en GitHub o requiere permiso admin:public_key."
        fi
    fi
}

# ─────────────────────────────────────────────────────────────
# Genera una nueva llave SSH Ed25519 y opcionalmente la guarda
# en Proton Pass y/o GitHub
# ─────────────────────────────────────────────────────────────
generate_ssh_key_interactive() {
    print_header "GENERAR NUEVA LLAVE SSH (ED25519)"
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    local default_email email
    default_email=$(git config --global user.email 2>/dev/null || echo "developer@herwingx.com")
    email=$(ui_input "Comentario / Correo para la llave SSH Ed25519" "$default_email")
    email="${email:-$default_email}"

    local key_file="$HOME/.ssh/id_ed25519"
    if [ -f "$key_file" ]; then
        if ! ui_confirm "Ya existe una llave en $key_file. ¿Deseas reemplazarla por una nueva?"; then
            print_info "Conservando la llave existente en $key_file."
            backup_ssh_key_to_cloud
            return 0
        fi
    fi

    ssh-keygen -t ed25519 -C "$email" -f "$key_file" -N ""
    chmod 600 "$key_file"
    chmod 644 "$key_file.pub"
    print_success "Llave SSH Ed25519 generada en $key_file"
    echo -e "${NEON_CYAN}  Llave pública ($key_file.pub):${NC}"
    cat "$key_file.pub"
    echo ""

    backup_ssh_key_to_cloud
}

# ─────────────────────────────────────────────────────────────
# Menú interactivo para gestión de llaves SSH (100% en español)
# ─────────────────────────────────────────────────────────────
setup_ssh_interactive() {
    print_header "GESTIÓN DE LLAVES Y AGENTE SSH (ED25519)"

    local opt_auto="1 :: 🔄 Configuración Automática (Crear Ed25519 si falta + GitHub authorized_keys + Proton Pass)"
    local opt_gen="2 :: ✨ Crear nueva llave SSH Ed25519 (~/.ssh/id_ed25519) y respaldar en Proton Pass / GitHub"
    local opt_backup="3 :: ☁️  Respaldar mi llave ~/.ssh/id_ed25519 actual en Proton Pass y GitHub"
    local opt_proton="4 :: 🔐 Cargar llaves SSH desde Proton Pass al agente (pass-cli ssh-agent)"
    local opt_wsl="5 :: 🪟 Copiar llaves SSH desde Windows (Solo WSL)"
    local opt_back="0 :: ↩️  Volver al menú principal"

    local choice
    choice=$(ui_choose "Selecciona una opción para tus llaves SSH:" \
        "$opt_auto" "$opt_gen" "$opt_backup" "$opt_proton" "$opt_wsl" "$opt_back") || return 0

    case "$choice" in
        "$opt_auto")
            install_ssh_keys
            configure_ssh_agent
            ;;
        "$opt_gen")
            generate_ssh_key_interactive
            configure_ssh_agent
            ;;
        "$opt_backup")
            backup_ssh_key_to_cloud
            configure_ssh_agent
            ;;
        "$opt_proton")
            "$DOTFILES_DIR/scripts/manage_secrets.sh" ssh-agent
            ;;
        "$opt_wsl")
            copy_ssh_from_windows
            configure_ssh_agent
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────
# Configura SSH Agent persistente en .bashrc (Local + Proton Pass)
# ─────────────────────────────────────────────────────────────
configure_ssh_agent() {
    print_step "Configurando SSH Agent auto-start en .bashrc..."

    local ssh_agent_block='# SSH Agent - Inicio automático (Compatible con Proton Pass SSH Agent y llaves locales)
if [ -S "$HOME/.ssh/proton-pass-agent.sock" ]; then
    export SSH_AUTH_SOCK="$HOME/.ssh/proton-pass-agent.sock"
elif [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null 2>&1
fi

if [ -f "$HOME/.ssh/id_ed25519" ]; then
    ssh-add -l 2>/dev/null | grep -q "id_ed25519" || ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null
elif [ -f "$HOME/.ssh/id_rsa" ]; then
    ssh-add -l 2>/dev/null | grep -q "id_rsa" || ssh-add "$HOME/.ssh/id_rsa" 2>/dev/null
fi'

    update_bashrc_block "SSH_AGENT" "$ssh_agent_block" "bottom"
    print_success "SSH Agent configurado en .bashrc."
}
