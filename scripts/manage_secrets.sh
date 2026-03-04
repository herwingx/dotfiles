#!/bin/bash
# ==============================================================================
# GESTOR DE SECRETOS AVANZADO (Vault Manager)
# ==============================================================================

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPTS_DIR="$(dirname "$SCRIPT_PATH")"
DOTFILES_DIR="$(dirname "$SCRIPTS_DIR")"

# Cargar helpers visuales
source "$DOTFILES_DIR/scripts/common.sh"

REPO_SECRETS="$DOTFILES_DIR/.env.age"
LOCAL_SECRETS="$DOTFILES_DIR/.env.local.age"
TEMP_FILE="$DOTFILES_DIR/.env.tmp"

# --- FUNCIONES DE ACCIÓN ---

# ─────────────────────────────────────────────────────────────
# Edita un archivo de secretos
#
# Desencripta el archivo especificado en un archivo temporal
# para ser editado y lo vuelve a encriptar con `age` al guardar.
#
# @param $1 - Archivo destino (ej. `.env.local.age`).
# @param $2 - Título para la UI.
# @sideeffects Usa el editor por defecto (`nano`) y modifica archivos.
# ─────────────────────────────────────────────────────────────
action_edit_file() {
    local target_file=$1
    local title=$2

    print_header "EDITING VAULT :: $title"
    
    # 1. Desencriptar
    if [ -f "$target_file" ]; then
        echo -e "${NEON_CYAN}  >> Decrypting vault...${NC}"
        age --decrypt "$target_file" > "$TEMP_FILE"
        if [ $? -ne 0 ]; then
            print_error "Decryption Failed (Wrong Passphrase?)"
            rm -f "$TEMP_FILE"
            read -p "  Press Enter to return..."
            return
        fi
    else
        echo -e "${NEON_GREEN}  >> Creating NEW vault...${NC}"
        touch "$TEMP_FILE"
        # Añadir template básico si es nuevo
        echo "# --- SECRETS VAULT ---" >> "$TEMP_FILE"
        echo "# GH_TOKEN=..." >> "$TEMP_FILE"
        echo "" >> "$TEMP_FILE"
    fi

    # 2. Editar
    EDITOR=${EDITOR:-nano}
    $EDITOR "$TEMP_FILE"

    # 3. Encriptar
    echo -e "${NEON_CYAN}  >> Encrypting changes...${NC}"
    echo -e "${GRAY}     (Enter passphrase for encryption)${NC}"
    
    age --passphrase --output "$target_file" "$TEMP_FILE"
    
    if [ $? -eq 0 ]; then
        rm "$TEMP_FILE"
        print_success "Vault Updated Successfully!"
    else
        print_error "Encryption Failed! Plaintext saved at: $TEMP_FILE"
    fi
    read -p "  Press Enter to continue..."
}

# ─────────────────────────────────────────────────────────────
# Visualiza un archivo de secretos
#
# Desencripta el archivo en memoria y lo muestra en pantalla
# de solo lectura.
#
# @param $1 - Archivo destino a leer.
# ─────────────────────────────────────────────────────────────
action_view_file() {
    local target_file=$1
    if [ ! -f "$target_file" ]; then
        print_warning "File not found: $target_file"
        read -p "  Press Enter..."
        return
    fi
    
    print_header "VIEWING VAULT CONTENT (READ-ONLY)"
    age --decrypt "$target_file"
    echo ""
    echo -e "${GRAY}------------------------------------------------${NC}"
    read -p "  Press Enter to return..."
}

# --- MENÚ INTERACTIVO ---

# ─────────────────────────────────────────────────────────────
# Muestra el menú principal de Vault Manager
#
# Renderiza la interfaz de usuario en la terminal y maneja
# el loop principal de interacción del usuario.
# ─────────────────────────────────────────────────────────────
show_menu() {
    clear
    echo -e "${NEON_GREEN}"
    cat << 'EOF'
   ▄▀▀ █▀▀ ▄▀▀ █▀▄ █▀▀ ▀█▀ ▄▀▀
   ▄██ ██▄ ▀▄▄ █▀▄ ██▄  █  ▄██   VAULT_MANAGER v2.0
EOF
    echo -e "${NC}"
    
    # Estado de los archivos
    echo -e "${GRAY}  STATUS:${NC}"
    if [ -f "$LOCAL_SECRETS" ]; then
        echo -e "  LOCAL: ${NEON_GREEN}DETECTED (.env.local.age)${NC} ${GRAY}(Priority)${NC}"
    else
        echo -e "  LOCAL: ${GRAY}NOT FOUND${NC}"
    fi
    if [ -f "$REPO_SECRETS" ]; then
        echo -e "  REPO : ${NEON_CYAN}DETECTED (.env.age)${NC}"
    else
        echo -e "  REPO : ${GRAY}NOT FOUND${NC}"
    fi
    echo ""

    echo -e "${NEON_CYAN}  // 🔓 LOCAL VAULT (Recommended)${NC}"
    echo -ne "  "; p_opt "1" "Edit Local Secrets"; echo ""
    echo -ne "  "; p_opt "2" "View Local Secrets"; echo ""
    echo ""

    echo -e "${NEON_CYAN}  // 📦 REPO VAULT (Backup/Dist)${NC}"
    echo -ne "  "; p_opt "3" "Edit Repo Secrets"; echo ""
    echo -ne "  "; p_opt "4" "View Repo Secrets"; echo ""
    echo ""

    echo -e "${GRAY}  +--------------------------------------------+${NC}"
    echo -ne "  "; p_opt "0" "EXIT"; echo ""
    echo ""
    
    echo -e "${GRAY}  [TIP] Local override Repo secrets automatically${NC}"
    echo -ne "${NEON_GREEN}vault@manager${NC}:${BLUE}~${NC}$ "
    read choice

    case $choice in
        1) action_edit_file "$LOCAL_SECRETS" "LOCAL (Private)" ;;
        2) action_view_file "$LOCAL_SECRETS" ;;
        3) action_edit_file "$REPO_SECRETS" "REPO (Shared)" ;;
        4) action_view_file "$REPO_SECRETS" ;;
        0) exit 0 ;;
        *) echo "Invalid option" ;;
    esac
}

# Compatibilidad CLI
if [ -n "$1" ]; then
    case "$1" in
        edit-local) action_edit_file "$LOCAL_SECRETS" "LOCAL" ;;
        edit-repo) action_edit_file "$REPO_SECRETS" "REPO" ;;
        view) action_view_file "$LOCAL_SECRETS" ;;
        *) echo "Usage: $0 {edit-local|edit-repo|view}" ;;
    esac
    exit 0
fi

while true; do show_menu; done
