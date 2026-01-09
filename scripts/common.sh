# --- PALETA DE COLORES HACKER (MATRIX/CYBERPUNK) ---
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'

# Colores Base
RED='\033[0;31m'
GREEN='\033[0;32m'
NEON_GREEN='\033[1;32m' # Main Accent
YELLOW='\033[1;33m'
BLUE='\033[0;34m' # Standard Blue
CYAN='\033[0;36m'
NEON_CYAN='\033[1;36m' # Secondary Accent
WHITE='\033[1;37m'
GRAY='\033[1;30m'     # Subtle details
NC='\033[0m'          # No Color

# --- DIRECTORIO BASE ---
if [ -z "$DOTFILES_DIR" ]; then
    SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
    DOTFILES_DIR="$(dirname "$(dirname "$SCRIPT_PATH")")"
fi

# --- HELPERS UI TÉCNICOS ---
print_header() {
    echo ""
    echo -e "${GRAY}===============================================================${NC}"
    echo -e "${NEON_GREEN}[+] SYSTEM_TASK :: ${WHITE}${1^^}${NC}" # Uppercase for tech look
    echo -e "${GRAY}===============================================================${NC}"
}

print_step() {
    echo -e "${NEON_CYAN}  >> ${NC}$1"
}

print_success() {
    echo -e "${NEON_GREEN}  [OK] ${NC}$1"
}

print_warning() {
    echo -e "${YELLOW}  [!] WARNING: ${NC}$1"
}

print_error() {
    echo -e "${RED}  [ERROR] ${NC}$1"
}

print_info() {
    echo -e "${GRAY}      # $1${NC}"
}

# --- DETECCIÓN DE ENTORNO ---
if [ "$(id -u)" -eq 0 ]; then
    SUDO_CMD=""
else
    SUDO_CMD="sudo"
fi

# --- GESTIÓN DE SECRETOS ---

# Función auxiliar para guiar la creación de secretos locales
create_local_secrets() {
    print_header "🔐 Configuración de Secretos Personales"
    
    echo -e "${CYAN}Vamos a crear tu propia bóveda de secretos local (.env.local.age).${NC}"
    print_info "Este archivo contendrá TUS claves y será ignorado por Git."
    echo ""
    
    # Input interactivo con estilo
    echo -e "${BOLD}Ingresa tus credenciales (Deja vacío para omitir):${NC}"
    read -p "   GitHub Token (GH_TOKEN): " NEW_GH_TOKEN
    
    if [ -n "$NEW_GH_TOKEN" ]; then
        # Crear contenido temporal
        TEMP_ENV=$(mktemp)
        echo "GH_TOKEN=$NEW_GH_TOKEN" > "$TEMP_ENV"
        
        echo ""
        print_step "Encriptando archivo seguro..."
        echo -e "${YELLOW}  > A continuación, age te pedirá una${BOLD} NUEVA passphrase${NC}${YELLOW} para proteger este archivo.${NC}"
        
        # Encriptar
        age --encrypt -p -o "$DOTFILES_DIR/.env.local.age" "$TEMP_ENV"
        RET_CODE=$?
        rm -f "$TEMP_ENV"
        
        if [ $RET_CODE -eq 0 ]; then
             print_success "Bóveda local creada: .env.local.age"
             
             # Asegurar gitignore
             if ! grep -q ".env.local.age" "$DOTFILES_DIR/.gitignore" 2>/dev/null; then
                 echo ".env.local.age" >> "$DOTFILES_DIR/.gitignore"
             fi
             
             # Limpieza UX: Ocultar el archivo del repo original para evitar confusión
             if [ -f "$DOTFILES_DIR/.env.age" ]; then
                 mv "$DOTFILES_DIR/.env.age" "$DOTFILES_DIR/.env.age.dist"
                 print_info "El archivo original .env.age ha sido archivado como .env.age.dist"
                 print_info "para que solo veas tu propia configuración."
             fi
             
             # Recargar recursivamente
             decrypt_secrets
             return $?
        else
             print_error "Error al encriptar. Inténtalo de nuevo."
             return 1
        fi
    else
        print_warning "No ingresaste token. Cancelando creación de secretos."
        return 1
    fi
}

decrypt_secrets() {
    # 1. PRIORIDAD: Archivo local propio
    if [ -f "$DOTFILES_DIR/.env.local.age" ]; then
        TARGET_FILE="$DOTFILES_DIR/.env.local.age"
        MSG_TYPE="Tu Bóveda Local 🏠 (.env.local.age)"
    # 2. FALLBACK: Archivo del repositorio
    elif [ -f "$DOTFILES_DIR/.env.age" ]; then
        TARGET_FILE="$DOTFILES_DIR/.env.age"
        MSG_TYPE="Bóveda del Repositorio 📦 (.env.age)"
    else
        # No existe ninguno, flujo de bienvenida
        echo ""
        echo -e "${PURPLE}┌───────────────────────────────────────────────────┐${NC}"
        echo -e "${PURPLE}│${NC}  ${BOLD}👋 Bienvenido a la Instalación de Dotfiles${NC}       ${PURPLE}│${NC}"
        echo -e "${PURPLE}└───────────────────────────────────────────────────┘${NC}"
        echo -e "${CYAN}No detectamos configuración de secretos.${NC}"
        echo ""
        echo -e "${BOLD}¿Qué deseas hacer?${NC}"
        echo -e "  ${GREEN}1)${NC} Configurar mis claves (Recomendado) ✨"
        echo -e "  ${DIM}2) Continuar en modo invitado (Sin funcionalidades Cloud)${NC}"
        echo ""
        read -p "  Selección [1-2]: " OPT
        case $OPT in
            1) create_local_secrets; return $? ;;
            *) return 0 ;;
        esac
    fi

    if [ -z "$SECRETS_LOADED" ]; then
        echo -e "${BLUE}🔐 Desbloqueando: ${BOLD}$MSG_TYPE${NC}"
        
        TEMP_ENV=$(mktemp)
        chmod 600 "$TEMP_ENV"
        
        # Ejecutamos age
        echo -e "${YELLOW}  🔑 Passphrase:${NC}"
        age --decrypt -o "$TEMP_ENV" "$TARGET_FILE"
        EXIT_CODE=$?
        
        if [ $EXIT_CODE -eq 0 ]; then
            DECRYPTED=$(cat "$TEMP_ENV")
            
            # Parsing de variables
            export BW_CLIENTID=$(echo "$DECRYPTED" | grep "^BW_CLIENTID=" | cut -d'=' -f2-)
            export BW_CLIENTSECRET=$(echo "$DECRYPTED" | grep "^BW_CLIENTSECRET=" | cut -d'=' -f2-)
            export GH_TOKEN=$(echo "$DECRYPTED" | grep "^GH_TOKEN=" | cut -d'=' -f2-)
            export TELEGRAM_BOT_TOKEN=$(echo "$DECRYPTED" | grep "^TELEGRAM_BOT_TOKEN=" | cut -d'=' -f2-)
            export TELEGRAM_CHAT_ID=$(echo "$DECRYPTED" | grep "^TELEGRAM_CHAT_ID=" | cut -d'=' -f2-)
            RCLONE_TOKEN_JSON=$(echo "$DECRYPTED" | grep "^RCLONE_TOKEN_JSON=" | cut -d'=' -f2-)
            
            # Configurar rclone
            if [ -n "$RCLONE_TOKEN_JSON" ]; then
                mkdir -p "$HOME/.config/rclone"
                cat > "$HOME/.config/rclone/rclone.conf" <<EOF
[gdrive]
type = drive
scope = drive
token = $RCLONE_TOKEN_JSON
team_drive =
EOF
                chmod 600 "$HOME/.config/rclone/rclone.conf"
            fi

            export SECRETS_LOADED=1
            print_success "Acceso concedido. Secretos cargados."
            rm -f "$TEMP_ENV"
            return 0
        else
            rm -f "$TEMP_ENV"
            echo ""
            print_error "Acceso denegado (Contraseña incorrecta)."
            
            echo -e "${BOLD}Opciones de Recuperación:${NC}"
            echo -e "  ${CYAN}1)${NC} Reintentar 🔄"
            echo -e "  ${CYAN}2)${NC} Crear NUEVA bóveda local (Ignorar esta) ✨"
            echo -e "  ${CYAN}3)${NC} Modo Invitado (Sin secretos) 👤"
            echo -e "  ${RED}4)${NC} Salir 🚪"
            
            read -p "  Elige una opción [1-4]: " OPTION
            case $OPTION in
                1) decrypt_secrets; return $? ;;
                2) create_local_secrets; return $? ;;
                3) print_warning "Modo Invitado activo."; return 0 ;;
                *) print_error "Instalación abortada."; exit 1 ;;
            esac
        fi
    fi
}

reload_shell() {
    print_header "Instalación Finalizada con Éxito"
    echo -e "${GREEN}  Recargando tu terminal para aplicar cambios... 🚀${NC}"
    echo ""
    exec bash
}


# Alias para compatibilidad con código existente
show_reload_message() {
    reload_shell
}
