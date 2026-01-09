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
# Función auxiliar para guiar la creación de secretos locales
create_local_secrets() {
    echo -e "${CYAN}=== Configuración de Secretos Propios ===${NC}"
    echo -e "${YELLOW}Vamos a crear un archivo encriptado local (.env.local.age) para tus credenciales.${NC}"
    echo -e "${YELLOW}Este archivo será ignorado por git y no afectará al repositorio.${NC}"
    echo ""
    
    read -p "GitHub Token (GH_TOKEN): " NEW_GH_TOKEN
    # Se podrían pedir más variables aquí (Bitwarden, Telegram, etc.)
    
    if [ -n "$NEW_GH_TOKEN" ]; then
        # Crear contenido temporal
        TEMP_ENV=$(mktemp)
        echo "GH_TOKEN=$NEW_GH_TOKEN" > "$TEMP_ENV"
        
        echo -e "${CYAN}Encriptando con age (te pedirá una nueva passphrase)...${NC}"
        age --encrypt -p -o "$DOTFILES_DIR/.env.local.age" "$TEMP_ENV"
        
        if [ $? -eq 0 ]; then
             echo -e "${GREEN}✓ Secretos locales guardados en .env.local.age${NC}"
             # Asegurar que esté en gitignore si no lo estaba
             if ! grep -q ".env.local.age" "$DOTFILES_DIR/.gitignore" 2>/dev/null; then
                 echo ".env.local.age" >> "$DOTFILES_DIR/.gitignore"
             fi
             rm -f "$TEMP_ENV"
             
             # Recargar recursivamente para aplicar los nuevos secretos
             decrypt_secrets
             return $?
        else
             echo -e "${RED}✗ Error al encriptar.${NC}"
             rm -f "$TEMP_ENV"
             return 1
        fi
    else
        echo -e "${YELLOW}Cancelado (Token vacío).${NC}"
        return 1
    fi
}

decrypt_secrets() {
    # 1. PRIORIDAD: Archivo local propio (.env.local.age)
    if [ -f "$DOTFILES_DIR/.env.local.age" ]; then
        TARGET_FILE="$DOTFILES_DIR/.env.local.age"
        MSG_TYPE="Locales (.env.local.age)"
    # 2. FALLBACK: Archivo del repositorio (.env.age)
    elif [ -f "$DOTFILES_DIR/.env.age" ]; then
        TARGET_FILE="$DOTFILES_DIR/.env.age"
        MSG_TYPE="Repositorio (.env.age)"
    else
        # No existe ninguno, ofrecer crear
        echo -e "${YELLOW}   ! No se encontraron archivos de secretos.${NC}"
        echo -e "${CYAN}   ¿Quieres configurar tus propias credenciales ahora?${NC}"
        echo "   1) Sí, configurar GH_TOKEN y crear .env.local.age"
        echo "   2) No, continuar en modo invitado"
        read -p "   Opción [1-2]: " OPT
        case $OPT in
            1) create_local_secrets; return $? ;;
            *) return 0 ;; # Modo invitado implícito
        esac
    fi

    if [ -z "$SECRETS_LOADED" ]; then
        echo -e "${CYAN}   🔐 Detectados secretos: $MSG_TYPE${NC}"
        
        TEMP_ENV=$(mktemp)
        chmod 600 "$TEMP_ENV"
        
        echo -e "${YELLOW}   Introduce la passphrase para desbloquear:${NC}"
        age --decrypt -o "$TEMP_ENV" "$TARGET_FILE"
        EXIT_CODE=$?
        
        if [ $EXIT_CODE -eq 0 ]; then
            DECRYPTED=$(cat "$TEMP_ENV")
            # Extraer variables
            export BW_CLIENTID=$(echo "$DECRYPTED" | grep "^BW_CLIENTID=" | cut -d'=' -f2-)
            export BW_CLIENTSECRET=$(echo "$DECRYPTED" | grep "^BW_CLIENTSECRET=" | cut -d'=' -f2-)
            export GH_TOKEN=$(echo "$DECRYPTED" | grep "^GH_TOKEN=" | cut -d'=' -f2-)
            export TELEGRAM_BOT_TOKEN=$(echo "$DECRYPTED" | grep "^TELEGRAM_BOT_TOKEN=" | cut -d'=' -f2-)
            export TELEGRAM_CHAT_ID=$(echo "$DECRYPTED" | grep "^TELEGRAM_CHAT_ID=" | cut -d'=' -f2-)
            export RCLONE_TOKEN_JSON=$(echo "$DECRYPTED" | grep "^RCLONE_TOKEN_JSON=" | cut -d'=' -f2-)
            
            # Configurar rclone si hay token
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
            echo -e "${RED}   ✗ Passphrase incorrecta o cancelada.${NC}"
            
            # MENÚ DE RECUPERACIÓN
            echo -e "${YELLOW}   ¿Qué deseas hacer?${NC}"
            echo "   1) Reintentar (me equivoqué de contraseña)"
            echo "   2) Ignorar este archivo y crear MIS PROPIOS secretos (.env.local.age)"
            echo "   3) Continuar en MODO INVITADO (sin secretos)"
            echo "   4) Abortar instalación"
            
            read -p "   Opción [1-4]: " OPTION
            case $OPTION in
                1) decrypt_secrets; return $? ;;
                2) create_local_secrets; return $? ;;
                3) echo -e "${YELLOW}   ⚠️  Modo Invitado activo.${NC}"; return 0 ;;
                *) echo -e "${RED}   ⛔ Cancelado por usuario.${NC}"; exit 1 ;;
            esac
        fi
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
