#!/bin/bash
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
    echo -e "${NEON_GREEN}[+] SYSTEM_TASK :: ${WHITE}${1^^}${NC}"
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

# Helper para UI de Opciones (Menús)
p_opt() {
    printf "${GRAY}[${WHITE}%-2s${GRAY}]${NC} %-40s" "$1" "$2"
}

# --- DETECCIÓN DE ENTORNO ---
if [ "$(id -u)" -eq 0 ]; then
    SUDO_CMD=""
else
    SUDO_CMD="sudo"
fi

# Detectar OS y Gestor de Paquetes Globalmente
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        debian|ubuntu|linuxmint|pop)
            OS_TYPE="debian"
            PKG_MANAGER="apt-get"
            PKG_UPDATE_CMD="$SUDO_CMD apt-get update -y"
            PKG_INSTALL_CMD="$SUDO_CMD apt-get install -y"
            ;;
        fedora|rhel|centos|almalinux|rocky)
            OS_TYPE="redhat"
            PKG_MANAGER="dnf"
            PKG_UPDATE_CMD="$SUDO_CMD dnf check-update"
            PKG_INSTALL_CMD="$SUDO_CMD dnf install -y"
            ;;
        arch|manjaro|endeavouros)
            OS_TYPE="arch"
            PKG_MANAGER="pacman"
            PKG_UPDATE_CMD="$SUDO_CMD pacman -Sy"
            PKG_INSTALL_CMD="$SUDO_CMD pacman -S --noconfirm"
            ;;
        opensuse*|suse)
            OS_TYPE="suse"
            PKG_MANAGER="zypper"
            PKG_UPDATE_CMD="$SUDO_CMD zypper refresh"
            PKG_INSTALL_CMD="$SUDO_CMD zypper install -y"
            ;;
        alpine)
            OS_TYPE="alpine"
            PKG_MANAGER="apk"
            PKG_UPDATE_CMD="$SUDO_CMD apk update"
            PKG_INSTALL_CMD="$SUDO_CMD apk add"
            ;;
        *)
            OS_TYPE="unknown"
            PKG_UPDATE_CMD="true"
            PKG_INSTALL_CMD="true"
            ;;
    esac
else
    # Fallback legacy
    if [ -f /etc/debian_version ]; then
        OS_TYPE="debian"
        PKG_MANAGER="apt-get"
        PKG_UPDATE_CMD="$SUDO_CMD apt-get update -y"
        PKG_INSTALL_CMD="$SUDO_CMD apt-get install -y"
    elif [ -f /etc/redhat-release ]; then
        OS_TYPE="redhat"
        PKG_MANAGER="dnf"
        PKG_UPDATE_CMD="$SUDO_CMD dnf check-update"
        PKG_INSTALL_CMD="$SUDO_CMD dnf install -y"
    elif [ -f /etc/arch-release ]; then
        OS_TYPE="arch"
        PKG_MANAGER="pacman"
        PKG_UPDATE_CMD="$SUDO_CMD pacman -Sy"
        PKG_INSTALL_CMD="$SUDO_CMD pacman -S --noconfirm"
    else
        OS_TYPE="unknown"
        PKG_UPDATE_CMD="true"
        PKG_INSTALL_CMD="true"
    fi
fi

# --- FUNCIONES CORE ---

# ─────────────────────────────────────────────────────────────
# Verificación idempotente de paquetes
#
# Instala un paquete solo si no está instalado o si el comando
# especificado no está en el PATH.
#
# @param $1 - Nombre del paquete en el gestor de paquetes.
# @param $2 - (Opcional) Comando binario a verificar (por defecto asume $1).
# @return 0 si ya estaba instalado o se instala con éxito, 1 si falla.
# ─────────────────────────────────────────────────────────────
ensure_package() {
    local package="$1"
    local binary="${2:-$package}" # Si no se pasa binario, asume que es igual al paquete

    # 1. Verificar si el binario existe en el PATH (Método más rápido y fiable)
    if command -v "$binary" &> /dev/null; then
        print_info "Package '$package' is already installed (binary: $binary)."
        return 0
    fi

    # 2. Si no hay binario, verificar vía gestor de paquetes (Fallback)
    local installed=false
    case "$OS_TYPE" in
        debian)
            dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "ok installed" && installed=true
            ;;
        redhat)
            rpm -q "$package" &> /dev/null && installed=true
            ;;
        arch)
            pacman -Qq "$package" &> /dev/null && installed=true
            ;;
        suse)
            rpm -q "$package" &> /dev/null && installed=true
            ;;
        alpine)
            apk info -e "$package" &> /dev/null && installed=true
            ;;
    esac

    if [ "$installed" = true ]; then
        print_info "Package '$package' is already installed (system verified)."
        return 0
    fi

    # 3. Instalación
    print_step "Installing $package..."
    $PKG_INSTALL_CMD "$package"

    if [ $? -eq 0 ]; then
        print_success "$package installed successfully."
    else
        print_error "Failed to install $package."
        return 1
    fi
}

# --- HELPERS CONFIGURACIÓN ---

# ─────────────────────────────────────────────────────────────
# Gestión robusta de bloques en .bashrc
#
# Inserta o actualiza un bloque de configuración en el archivo
# .bashrc rodeándolo de marcadores de inicio y fin para fácil reemplazo.
#
# @param $1 - Nombre único para el bloque (ej. "ALIASES").
# @param $2 - Contenido del bloque a insertar.
# @param $3 - Modo de inserción: "top" o "bottom".
# ─────────────────────────────────────────────────────────────
update_bashrc_block() {
    local name="$1"
    local content="$2"
    local mode="$3"
    local bashrc="$HOME/.bashrc"
    
    local start="<!-- BEGIN_${name} -->"
    local end="<!-- END_${name} -->"
    
    # 1. Limpiar bloque existente
    sed -i "/$start/,/$end/d" "$bashrc"
    
    # 2. Preparar nuevo bloque
    local block="# $start
$content
# $end"

    # 3. Insertar según modo
    if [ "$mode" == "top" ]; then
        cp "$bashrc" "$bashrc.tmp"
        echo "$block" > "$bashrc"
        echo "" >> "$bashrc"
        cat "$bashrc.tmp" >> "$bashrc"
        rm -f "$bashrc.tmp"
        
    else # bottom
        echo "" >> "$bashrc"
        echo "$block" >> "$bashrc"
    fi
}

# ─────────────────────────────────────────────────────────────
# Detecta editor de código compatible
#
# Busca en el PATH editores compatibles (code, codium, cursor).
#
# @return 0 e imprime el comando si lo encuentra, 1 si no.
# ─────────────────────────────────────────────────────────────
detect_editor() {
    local editors=("code" "codium" "cursor")
    for cmd in "${editors[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            echo "$cmd"
            return 0
        fi
    done
    return 1
}

# --- GESTIÓN DE SECRETOS ---

# ─────────────────────────────────────────────────────────────
# Reinicio interactivo de la bóveda de secretos
#
# Pregunta al usuario si desea recrear su archivo .env.local.age
# alertándole que la versión existente se sobrescribirá.
# ─────────────────────────────────────────────────────────────
reset_secrets_interactive() {
    print_header "RESET SECRETS VAULT"
    echo -e "${YELLOW}  [!] WARNING: A NEW local secrets vault will be generated.${NC}"
    echo -e "${GRAY}      If .env.local.age exists, it will be OVERWRITTEN.${NC}"
    echo ""
    
    if [ -f "$DOTFILES_DIR/.env.age" ]; then
        echo -e "${NEON_CYAN}  [INFO] FORK DETECTED :: Original .env.age found.${NC}"
        echo -e "${GRAY}         Creating your own vault allows you to safely remove/archive${NC}"
        echo -e "${GRAY}         the original author's encrypted file.${NC}" 
        echo ""
    fi
    
    echo -ne "${NEON_GREEN}  >> Proceed with new vault creation? [y/N]: ${NC}"
    read CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        create_local_secrets
    else
        print_warning "Aborted by user."
    fi
}

# ─────────────────────────────────────────────────────────────
# Crea una bóveda de secretos local (.env.local.age)
#
# Pide las credenciales por CLI y las encripta con age.
# Ignora el archivo en git.
# ─────────────────────────────────────────────────────────────
create_local_secrets() {
    print_header "🔐 Configuración de Secretos Personales"
    
    echo -e "${CYAN}Vamos a crear tu propia bóveda de secretos local (.env.local.age).${NC}"
    print_info "Este archivo contendrá TUS claves y será ignorado por Git."
    echo ""
    echo -e "${GRAY}  [TIP] Press Ctrl+C to cancel operation${NC}"
    
    echo -e "${BOLD}Ingresa tus credenciales (Deja vacío para omitir):${NC}"
    read -p "   GitHub Token (GH_TOKEN): " NEW_GH_TOKEN
    
    if [ -n "$NEW_GH_TOKEN" ]; then
        TEMP_ENV=$(mktemp)
        echo "GH_TOKEN=$NEW_GH_TOKEN" > "$TEMP_ENV"
        
        echo ""
        print_step "Encriptando archivo seguro..."
        echo -e "${YELLOW}  > A continuación, age te pedirá una${BOLD} NUEVA passphrase${NC}${YELLOW} para proteger este archivo.${NC}"
        
        ensure_package "age"
        age --encrypt -p -o "$DOTFILES_DIR/.env.local.age" "$TEMP_ENV"
        RET_CODE=$?
        rm -f "$TEMP_ENV"
        
        if [ $RET_CODE -eq 0 ]; then
             print_success "Bóveda local creada: .env.local.age"
             
             if ! grep -q ".env.local.age" "$DOTFILES_DIR/.gitignore" 2>/dev/null; then
                 echo ".env.local.age" >> "$DOTFILES_DIR/.gitignore"
             fi
             
             if [ -f "$DOTFILES_DIR/.env.age" ]; then
                 mv "$DOTFILES_DIR/.env.age" "$DOTFILES_DIR/.env.age.dist"
                 print_info "Original .env.age archived as .env.age.dist"
             fi
             
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

# ─────────────────────────────────────────────────────────────
# Desencripta y carga los secretos en la sesión actual
#
# Intenta desencriptar .env.local.age (o .env.age como fallback)
# solicitando la contraseña si es necesario. Carga variables
# en la sesión y las configura para aplicaciones como rclone.
# ─────────────────────────────────────────────────────────────
decrypt_secrets() {
    ensure_package "age"
    
    if [ -f "$DOTFILES_DIR/.env.local.age" ]; then
        TARGET_FILE="$DOTFILES_DIR/.env.local.age"
        MSG_TYPE="Tu Bóveda Local 🏠 (.env.local.age)"
    elif [ -f "$DOTFILES_DIR/.env.age" ]; then
        TARGET_FILE="$DOTFILES_DIR/.env.age"
        MSG_TYPE="Bóveda del Repositorio 📦 (.env.age)"
    else
        print_header "SECRETS VAULT SETUP"
        echo -e "${NEON_CYAN}  >> No existing secrets vault detected.${NC}"
        echo -e "${GRAY}     You can create a secure vault now or proceed as guest.${NC}"
        echo ""
        
        echo -e "${NEON_CYAN}  // OPTIONS${NC}"
        echo -e "${GRAY}  +--------------------------------------------+${NC}"
        echo -e "  ${WHITE}[1]${NC} Configure My Secrets ${GRAY}(Recommended)${NC}"
        echo -e "  ${WHITE}[2]${NC} Guest Mode ${GRAY}(No Cloud Integrations)${NC}"
        echo ""
        
        echo -ne "${NEON_GREEN}  >> Select Option [1-2]: ${NC}"
        read OPT
        case $OPT in
            1) create_local_secrets; return $? ;;
            *) return 0 ;;
        esac
    fi

    if [ -z "$SECRETS_LOADED" ]; then
        print_header "UNLOCKING SECRETS VAULT :: $MSG_TYPE"
        
        TEMP_ENV=$(mktemp)
        chmod 600 "$TEMP_ENV"
        
        echo -e "${YELLOW}  🔑 Passphrase:${NC}"
        age --decrypt -o "$TEMP_ENV" "$TARGET_FILE"
        EXIT_CODE=$?
        
        if [ $EXIT_CODE -eq 0 ]; then
            set -a
            source "$TEMP_ENV"
            set +a
            
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
            
            if [ -n "$GH_TOKEN" ]; then
                print_success "GitHub Token cargado."
            fi
            if [ -n "$ATUIN_KEY" ]; then
                print_success "Atuin Key cargada."
            fi

            export SECRETS_LOADED=1
            print_success "Acceso concedido. Secretos cargados."
            
            shred -u "$TEMP_ENV" 2>/dev/null || rm -f "$TEMP_ENV"
            return 0
        else
            rm -f "$TEMP_ENV"
            echo ""
            print_error "ACCESS DENIED :: Incorrect Passphrase"
            
            echo -e "${NEON_CYAN}  // RECOVERY OPTIONS${NC}"
            echo -e "${GRAY}  +--------------------------------------------+${NC}"
            echo -e "  ${WHITE}[1]${NC} Retry Passphrase ${GRAY}(Try again)${NC}"
            echo -e "  ${WHITE}[2]${NC} Create NEW Local Vault ${GRAY}(Reset/Ignore)${NC}"
            echo -e "  ${WHITE}[3]${NC} Guest Mode ${GRAY}(No secrets)${NC}"
            echo -e "  ${WHITE}[4]${NC} Abort / Exit"
            echo ""
            echo -ne "${NEON_GREEN}  >> Select Option [1-4]: ${NC}"
            
            read OPTION
            case $OPTION in
                1) decrypt_secrets; return $? ;;
                2) create_local_secrets; return $? ;;
                3) print_warning "Guest Mode Active."; return 0 ;;
                *) print_error "Aborted by User."; exit 1 ;;
            esac
        fi
    fi
}

# ─────────────────────────────────────────────────────────────
# Recarga la shell actual
#
# Ejecuta `exec bash` para aplicar cambios de entorno.
# ─────────────────────────────────────────────────────────────
reload_shell() {
    print_header "Reloading Shell..."
    echo -e "${GREEN}  Applying changes... 🚀${NC}"
    echo ""
    exec bash
}
