#!/bin/bash
# ==============================================================================
# CLOUD.SH - Configuración de Rclone y Sincronización Cloud con Proton Pass
# ==============================================================================

# ─────────────────────────────────────────────────────────────
# Configura rclone para Google Drive usando secretos de Proton Pass
# Si estamos en Guest Mode (distro limpia sin credenciales), omite sin error.
# ─────────────────────────────────────────────────────────────
configure_rclone() {
    print_step "Configurando rclone..."

    ensure_package "rclone"

    load_secrets

    if [ -n "${RCLONE_TOKEN_JSON:-}" ]; then
        mkdir -p "$HOME/.config/rclone"
        cat > "$HOME/.config/rclone/rclone.conf" <<EOF
[gdrive]
type = drive
scope = drive
token = $RCLONE_TOKEN_JSON
team_drive =
EOF
        chmod 600 "$HOME/.config/rclone/rclone.conf"

        print_success "rclone configurado exitosamente (~/.config/rclone/rclone.conf)."
        echo -e "${CYAN}   Remotes disponibles:${NC}"
        rclone listremotes | sed 's/^/     /'
        return 0
    fi

    if [ "${GUEST_MODE:-}" == "true" ]; then
        print_info "Guest Mode: rclone instalado. Ejecuta './install.sh --secrets' luego para vincular Google Drive."
        return 0
    fi

    print_warning "RCLONE_TOKEN_JSON no encontrado. Configúralo con './scripts/manage_secrets.sh'."
    return 0
}
