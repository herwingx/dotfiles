#!/bin/bash
# ==========================================
# CLOUD - Configuración de servicios cloud
# ==========================================
# Funciones para configurar servicios de almacenamiento cloud.
# Actualmente soporta: rclone para Google Drive.
# ==========================================

# ─────────────────────────────────────────────────────────────
# Configura rclone para Google Drive usando token de secrets.
# Fuerza el descifrado de secrets para obtener RCLONE_TOKEN_JSON.
# Verifica la conexión tras la configuración.
# ─────────────────────────────────────────────────────────────
configure_rclone() {
    print_step "Configurando rclone..."
    
    # 1. Idempotency: Install rclone using package manager if missing
    ensure_package "rclone"
    
    # 2. Secret Management
    # Force secret decryption to ensure variables are fresh
    unset SECRETS_LOADED
    
    if decrypt_secrets; then
        if [ -n "$RCLONE_TOKEN_JSON" ]; then
             mkdir -p "$HOME/.config/rclone"
             
             # Create config file idempotently (overwrite)
             cat > "$HOME/.config/rclone/rclone.conf" <<EOF
[gdrive]
type = drive
scope = drive
token = $RCLONE_TOKEN_JSON
team_drive =
EOF
             chmod 600 "$HOME/.config/rclone/rclone.conf"
             
             print_success "rclone configured successfully"
             echo -e "${CYAN}   Remotes available:${NC}"
             rclone listremotes
        else
            print_error "RCLONE_TOKEN_JSON not found in decrypted secrets."
        fi
    else
        print_error "Failed to decrypt secrets."
    fi
}
