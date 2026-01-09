#!/bin/bash
# ==========================================
# DOTFILES INSTALLER
# Instalador interactivo modular para Linux
# ==========================================

# Obtener directorio real del script (no depende de pwd)
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(dirname "$SCRIPT_PATH")"

# --- CARGAR MÓDULOS ---
source "$DOTFILES_DIR/scripts/common.sh"
source "$DOTFILES_DIR/scripts/system.sh"
source "$DOTFILES_DIR/scripts/git.sh"
source "$DOTFILES_DIR/scripts/dev-tools.sh"
source "$DOTFILES_DIR/scripts/antigravity.sh"
source "$DOTFILES_DIR/scripts/cloud.sh"

# --- FUNCIONES DE INSTALACIÓN AGRUPADAS ---

install_all() {
    export AUTO_INSTALL=true
    
    update_system
    install_packages
    configure_rclone
    install_gitconfig
    install_ssh_keys
    install_dev_tools_all
    install_antigravity_full
    install_auto_update
    show_reload_message
}

# --- ASCII ART HIGH-TECH ---
show_banner() {
    clear
    echo -e "${NEON_GREEN}"
    cat << 'EOF'
  ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
  ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██╔╝██║     ██╔════╝██╔════╝
  ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
  ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
  ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
  ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
                            v2.0_PREMIUM_BUILD // SYSTEM_READY
EOF
    echo -e "${NC}"
    echo -e "${GRAY}----------------------------------------------------------------${NC}"
    echo -e "${WHITE}  SYSTEM :: ${NEON_CYAN}$(uname -n) [$(uname -s)]${NC}"
    echo -e "${WHITE}  USER   :: ${NEON_CYAN}$(whoami)${NC}"
    echo -e "${GRAY}----------------------------------------------------------------${NC}"
    echo ""
}

# --- ERROR HANDLING ---
handle_error() {
    local exit_code=$1
    local task=$2
    if [ $exit_code -ne 0 ]; then
        echo ""
        print_error "EXECUTION FAILED :: ${BOLD}$task${NC}"
        echo -e "${YELLOW}  [DEBUG_INFO]:${NC}"
        echo -e "   - Check Network Connection"
        echo -e "   - Verify SUDO privileges"
        echo -e "   - Try: ${DIM}sudo apt update --fix-missing${NC}"
        echo ""
        read -p "  [PRESS ENTER TO CONTINUE OR CTRL+C TO ABORT]..."
    fi
}

# --- MENÚ INTERACTIVO TÉCNICO ---
show_menu() {
    show_banner
    
    # Grid Layout Helper
    # $1=Num $2=Desc
    p_opt() {
        printf "${GRAY}[${WHITE}%-2s${GRAY}]${NC} %-38s" "$1" "$2"
    }

    echo -e "${NEON_GREEN}  // 🚀 INSTALACIÓN AUTOMÁTICA${NC}"
    echo -e "${GRAY}  +------------------------------------------------------------+${NC}"
    
    # Fila 1: Full
    echo -ne "  "; p_opt "1" "Instalar TODO (Full Stack + IA + Cloud)"; echo ""
    echo -e "${GRAY}  +------------------------------------------------------------+${NC}"
    
    # Fila 2: Groups
    echo -ne "  "; p_opt "2" "Solo Sistema (Esenciales + Shell)"; p_opt "3" "Solo Dev Tools (Docker + Node)"; echo ""
    echo -ne "  "; p_opt "4" "Solo Antigravity AI (Reglas + Flows)"; echo ""
    echo -e "${GRAY}  +------------------------------------------------------------+${NC}"
    echo ""

    echo -e "${NEON_CYAN}  // 📦 MÓDULOS DE SISTEMA${NC}"
    echo -ne "  "; p_opt "5" "Actualizar Sistema (OS Upgrade)"; p_opt "6" "Paquetes Base (vim, fzf, tmux...)"; echo ""
    echo -ne "  "; p_opt "7" "Configurar Git y Alias"; p_opt "8" "Importar Keys SSH (desde GitHub)"; echo ""
    echo -ne "  "; p_opt "9" "Sincronizar SSH desde Windows (WSL)"; echo ""
    echo ""

    echo -e "${NEON_CYAN}  // 🛠️ HERRAMIENTAS DEV${NC}"
    echo -ne "  "; p_opt "10" "Instalar GitHub CLI (gh)"; p_opt "11" "Instalar Node.js (LTS)"; echo ""
    echo -ne "  "; p_opt "12" "Instalar Globales NPM"; p_opt "13" "Instalar Docker Engine"; echo ""
    echo ""

    echo -e "${NEON_CYAN}  // ☁️ CLOUD & INTEGRACIÓN IA${NC}"
    echo -ne "  "; p_opt "14" "Instalar Reglas IA (GEMINI.md)"; p_opt "15" "Instalar Comandos Slash (/commit...)"; echo ""
    echo -ne "  "; p_opt "16" "Desencriptar/Cargar Secretos"; p_opt "17" "Crear Nueva Bóveda (Reset Secrets)"; echo ""
    echo -ne "  "; p_opt "18" "Configurar Rclone (Google Drive)"; echo ""
    echo ""

    echo -e "${NEON_CYAN}  // 🔄 MANTENIMIENTO${NC}"
    echo -ne "  "; p_opt "19" "Activar Auto-Updates"; p_opt "20" "Ejecutar Update Manual"; echo ""
    echo -ne "  "; p_opt "21" "Desactivar Auto-Updates"; echo ""
    echo ""
    
    echo -e "${GRAY}  +------------------------------------------------------------+${NC}"
    echo -ne "  "; p_opt "0" "ABORT / EXIT"; echo ""
    echo ""
    
    echo -e "${GRAY}  [TIP] Press Ctrl+C to force quit at any time${NC}"
    echo -ne "${NEON_GREEN}wrapper@install${NC}:${BLUE}~${NC}$ "
    read choice
    
    case $choice in
        1) install_all || handle_error $? "FULL_STACK_DEPLOY" ;;
        2) install_system_all || handle_error $? "SYSTEM_ONLY_DEPLOY" ;;
        3) install_dev_tools_all || handle_error $? "DEV_TOOLS_DEPLOY" ;;
        4) install_antigravity_full || handle_error $? "ANTIGRAVITY_DEPLOY" ;;
        5) update_system || handle_error $? "SYSTEM_UPGRADE" ;;
        6) install_packages || handle_error $? "BASE_PACKAGES" ;;
        7) install_gitconfig || handle_error $? "GIT_CONFIG" ;;
        8) install_ssh_keys || handle_error $? "SSH_CONFIG" ;;
        9) copy_ssh_from_windows || handle_error $? "WSL_SYNC" ;;
        10) install_gh_cli || handle_error $? "GH_CLI_DEPLOY" ;;
        11) install_nvm_node || handle_error $? "NODEJS_DEPLOY" ;;
        12) install_npm_global_packages || handle_error $? "NPM_GLOBALS" ;;
        13) install_docker || handle_error $? "DOCKER_DEPLOY" ;;
        14) install_antigravity_rules || handle_error $? "AI_RULES" ;;
        15) install_antigravity_workflows || handle_error $? "AI_WORKFLOWS" ;;
        16) install_gemini_settings || handle_error $? "SECRETS_CONFIG" ;;
        17) reset_secrets_interactive || handle_error $? "NEW_VAULT_CREATION" ;;
        18) configure_rclone || handle_error $? "RCLONE_CONFIG" ;;
        19) install_auto_update || handle_error $? "AUTO_UPDATE_ENABLE" ;;
        20) run_manual_update || handle_error $? "MANUAL_UPDATE" ;;
        21) uninstall_auto_update || handle_error $? "AUTO_UPDATE_DISABLE" ;;
        0)
            echo ""
            echo -e "${NEON_GREEN}  >> SYSTEM SHUTDOWN... GOODBYE.${NC}"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}  [ERROR] INVALID COMMAND SENT${NC}"
            sleep 1
            ;;
    esac
}

# --- MAIN ---

if [ "$1" == "--all" ]; then
    print_header "INITIATING AUTOMATED DEPLOYMENT..."
    install_all
    exit 0
fi

while true; do
    show_menu
    echo ""
    echo -e "${GRAY}  [PRESS ENTER TO RETURN TO MENU]${NC}"
    read -r
done