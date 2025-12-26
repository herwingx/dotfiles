#!/bin/bash
# ==========================================
# COMMON - Variables globales y utilidades
# ==========================================
# Este módulo contiene las configuraciones base que todos
# los demás módulos necesitan: colores, detección de permisos
# y la función de descifrado de secrets.
# ==========================================

# --- COLORES ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ─────────────────────────────────────────────────────────────
# Detecta si el script corre como root (LXC) o usuario (VM).
# Configura SUDO_CMD vacío para root, "sudo" para usuario.
# ─────────────────────────────────────────────────────────────
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${YELLOW}>>> Ejecutando como ROOT (Modo LXC detectado)${NC}"
    SUDO_CMD=""
else
    echo -e "${YELLOW}>>> Ejecutando como USUARIO (Modo VM detectado)${NC}"
    SUDO_CMD="sudo"
fi

# ─────────────────────────────────────────────────────────────
# Descifra el archivo .env.age y exporta las credenciales.
# 
# Variables exportadas:
#   - BW_CLIENTID, BW_CLIENTSECRET: API keys de Bitwarden
#   - GH_TOKEN: Token de GitHub
#   - Configura rclone si RCLONE_TOKEN_JSON está presente
#
# @returns 0 si descifrado exitoso, 1 si error
# ─────────────────────────────────────────────────────────────
decrypt_secrets() {
    if [ -f "$DOTFILES_DIR/.env.age" ]; then
        # Instalar age si no existe
        if ! command -v age &> /dev/null; then
            echo -e "${YELLOW}   age no instalado, instalando...${NC}"
            if [ -f /etc/debian_version ]; then
                $SUDO_CMD apt-get install -y age
            elif [ -f /etc/redhat-release ]; then
                $SUDO_CMD dnf install -y age
            elif [ -f /etc/arch-release ]; then
                $SUDO_CMD pacman -S age --noconfirm
            fi
        fi
        
        if [ -z "$SECRETS_LOADED" ]; then
            echo -e "${CYAN}   Descifrando secrets...${NC}"
            DECRYPTED=$(age --decrypt "$DOTFILES_DIR/.env.age" 2>/dev/null)
            if [ $? -eq 0 ]; then
                # Extraer variables soportando valores con '='
                export BW_CLIENTID=$(echo "$DECRYPTED" | grep "^BW_CLIENTID=" | cut -d'=' -f2-)
                export BW_CLIENTSECRET=$(echo "$DECRYPTED" | grep "^BW_CLIENTSECRET=" | cut -d'=' -f2-)
                export GH_TOKEN=$(echo "$DECRYPTED" | grep "^GH_TOKEN=" | cut -d'=' -f2-)
                
                # Configurar rclone si hay token
                RCLONE_TOKEN_JSON=$(echo "$DECRYPTED" | grep "^RCLONE_TOKEN_JSON=" | cut -d'=' -f2-)
                
                if [ -n "$RCLONE_TOKEN_JSON" ]; then
                    echo -e "${CYAN}   Configurando rclone (generando desde token)...${NC}"
                    mkdir -p "$HOME/.config/rclone"
                    
                    cat > "$HOME/.config/rclone/rclone.conf" <<EOF
[gdrive]
type = drive
scope = drive
token = $RCLONE_TOKEN_JSON
team_drive =
EOF
                    chmod 600 "$HOME/.config/rclone/rclone.conf"
                    
                    echo -e "${CYAN}   Verificando conexión rclone...${NC}"
                    if rclone listremotes &>/dev/null; then
                        echo -e "${CYAN}   Remotos disponibles: $(rclone listremotes)${NC}"
                        if rclone lsd gdrive: --max-depth 1 &>/dev/null; then 
                             echo -e "${CYAN}   ✓ Conexión a gdrive exitosa${NC}"
                        else
                             echo -e "${YELLOW}   ! Configuración creada pero fallo al conectar (token expirado?)${NC}"
                        fi
                    fi
                fi

                export SECRETS_LOADED=1
                echo -e "${CYAN}   ✓ Secrets cargados${NC}"
                return 0
            else
                echo -e "${RED}   ✗ Error descifrando (passphrase incorrecta?)${NC}"
                return 1
            fi
        fi
    else
        echo -e "${YELLOW}   ! Archivo .env.age no encontrado${NC}"
        return 1
    fi
}
