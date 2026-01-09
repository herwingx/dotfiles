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

# --- DIRECTORIO BASE ---
# Si DOTFILES_DIR no está definido, calcularlo desde la ubicación de este script
if [ -z "$DOTFILES_DIR" ]; then
    SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
    DOTFILES_DIR="$(dirname "$(dirname "$SCRIPT_PATH")")"
fi

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
            echo -e "${CYAN}   🔐 Archivo de secretos (.env.age) detectado.${NC}"
            
            # Usar archivo temporal seguro para permitir interacción con age (stdin/stderr)
            TEMP_ENV=$(mktemp)
            chmod 600 "$TEMP_ENV"
            
            echo -e "${YELLOW}   Introduce la frase de paso para desbloquear los secretos:${NC}"
            # Ejecutamos age de forma directa para que pueda pedir password en la terminal
            age --decrypt -o "$TEMP_ENV" "$DOTFILES_DIR/.env.age"
            
            EXIT_CODE=$?
            
            if [ $EXIT_CODE -eq 0 ]; then
                DECRYPTED=$(cat "$TEMP_ENV")
                
                # Extraer variables soportando valores con '='
                export BW_CLIENTID=$(echo "$DECRYPTED" | grep "^BW_CLIENTID=" | cut -d'=' -f2-)
                export BW_CLIENTSECRET=$(echo "$DECRYPTED" | grep "^BW_CLIENTSECRET=" | cut -d'=' -f2-)
                export GH_TOKEN=$(echo "$DECRYPTED" | grep "^GH_TOKEN=" | cut -d'=' -f2-)
                export TELEGRAM_BOT_TOKEN=$(echo "$DECRYPTED" | grep "^TELEGRAM_BOT_TOKEN=" | cut -d'=' -f2-)
                export TELEGRAM_CHAT_ID=$(echo "$DECRYPTED" | grep "^TELEGRAM_CHAT_ID=" | cut -d'=' -f2-)
                
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
                echo -e "${CYAN}   ✓ Secrets cargados exitosamente${NC}"
                rm -f "$TEMP_ENV"
                return 0
            else
                rm -f "$TEMP_ENV"
                echo -e "${RED}   ✗ No se pudo desbloquear (Password incorrecto o cancelado).${NC}"
                echo -e "${YELLOW}   ¿Deseas continuar la instalación en 'Modo Invitado' (sin secretos)?${NC}"
                read -p "   [S/n]: " GUEST_MODE
                GUEST_MODE=${GUEST_MODE:-S}
                
                if [[ "$GUEST_MODE" =~ ^[Ss]$ ]]; then
                     echo -e "${YELLOW}   ⚠️  Continuando sin cargar secretos (GH_TOKEN, Bitwarden, etc. estarán vacíos).${NC}"
                     return 0 # Retornamos éxito para no romper el script de instalación
                else
                     return 1 # Fallo real, aborta instalación
                fi
            fi
        fi
    else
        echo -e "${YELLOW}   ! Archivo .env.age no encontrado${NC}"
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────
# Recarga la terminal automáticamente para aplicar aliases.
# Usa exec bash para reemplazar el shell actual con uno nuevo.
# ─────────────────────────────────────────────────────────────
reload_shell() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}   ✓ Instalación completa. Recargando terminal...${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    exec bash
}

# Alias para compatibilidad con código existente
show_reload_message() {
    reload_shell
}
