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
    echo -e "${GREEN}>>> Configurando rclone...${NC}"
    
    if ! command -v rclone &> /dev/null; then
        echo -e "${YELLOW}   ! rclone no está instalado. Instalando...${NC}"
        install_packages
    fi
    
    # Forzar descifrado de secrets
    unset SECRETS_LOADED
    
    if decrypt_secrets; then
        if [ -f "$HOME/.config/rclone/rclone.conf" ]; then
            echo -e "${CYAN}   ✓ rclone configurado correctamente${NC}"
            echo -e "${CYAN}   Remotos disponibles:${NC}"
            rclone listremotes
        else
            echo -e "${RED}   ✗ No se encontró RCLONE_TOKEN_JSON en los secrets${NC}"
        fi
    else
        echo -e "${RED}   ✗ Error descifrando secrets${NC}"
    fi
}
