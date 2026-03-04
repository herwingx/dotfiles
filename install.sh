#!/bin/bash
# ==========================================
# DOTFILES INSTALLER v2.0
# Instalador interactivo idempotente (Mise + Package Managers)
# ==========================================

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(dirname "$SCRIPT_PATH")"

# ─────────────────────────────────────────────────────────────
# ORQUESTADOR PRINCIPAL (INSTALL.SH)
#
# Este script inicializa el entorno y ofrece un menú interactivo
# para ejecutar todas o partes de las configuraciones de dotfiles.
# Los comandos están separados por módulos para mayor mantenibilidad.
# ─────────────────────────────────────────────────────────────

# --- CARGAR MÓDULOS ---
source "$DOTFILES_DIR/scripts/common.sh"
source "$DOTFILES_DIR/scripts/system.sh"
source "$DOTFILES_DIR/scripts/git.sh"
source "$DOTFILES_DIR/scripts/toolchain.sh" # NEW: Mise handler
source "$DOTFILES_DIR/scripts/dev-tools.sh"
source "$DOTFILES_DIR/scripts/antigravity.sh"
source "$DOTFILES_DIR/scripts/cloud.sh"
source "$DOTFILES_DIR/scripts/extensions.sh"
source "$DOTFILES_DIR/scripts/cron-update.sh"

install_all() {
    export AUTO_INSTALL=true
    
    # 1. Update System (Smart check <24h)
    update_system        
    
    # 2. Base Packages
    install_packages     
    
    # 3. Toolchain (Mise)
    install_toolchain    
    
    # 4. Config & Cloud
    configure_rclone
    install_gitconfig
    install_ssh_keys
    configure_ssh_agent
    
    # 5. Heavy Tools (Docker, GH CLI)
    install_dev_tools_all 
    
    # 6. Extras
    install_antigravity_full
    install_vscode_extensions
    install_auto_update
    
    show_reload_message
}

install_system_all() {
    update_system
    install_packages
    install_toolchain
    install_gitconfig
    install_ssh_keys
    configure_ssh_agent
    show_reload_message
}

show_reload_message() {
    print_header "Instalación Finalizada con Éxito"
    echo -e "${GREEN}  Recargando tu terminal para aplicar cambios... 🚀${NC}"
    echo ""
    exec bash
}

show_banner() {
    clear
    echo -e "${NEON_GREEN}   DOTFILES v2.0 (IDEMPOTENT)${NC}"
    echo -e "${NEON_GREEN}"
    cat << 'EOF'
  ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
  ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██╔╝██║     ██╔════╝██╔════╝
  ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
  ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
  ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
  ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
                            v2.5_IDEMPOTENT // MISE_POWERED
EOF
    echo -e "${NC}"
    echo -e "${GRAY}----------------------------------------------------------------${NC}"
    echo -e "${WHITE}  SYSTEM :: ${NEON_CYAN}$(uname -n) [${OS_TYPE^^}]${NC}"
    echo -e "${WHITE}  USER   :: ${NEON_CYAN}$(whoami)${NC}"
    echo -e "${GRAY}----------------------------------------------------------------${NC}"
    echo ""
}

handle_error() {
    local exit_code=$1
    local task=$2
    if [ $exit_code -ne 0 ]; then
        echo ""
        print_error "EXECUTION FAILED :: ${BOLD}$task${NC}"
        echo -e "${YELLOW}  [DEBUG_INFO]:${NC}"
        echo -e "   - Check Network Connection"
        echo -e "   - Verify SUDO privileges"
        echo -e "   - Log: /var/log/syslog or similar"
        echo ""
        read -p "  [PRESS ENTER TO CONTINUE]..."
    fi
}

show_menu() {
    show_banner
    # p_opt ahora se carga desde common.sh

    echo -e "${NEON_GREEN}  // 🚀 AUTOMATED DEPLOY${NC}"
    echo -e "${GRAY}  +------------------------------------------------------------+${NC}"
    echo -ne "  "; p_opt "1" "Full Install (System + Tools + AI)"; echo ""
    echo -e "${GRAY}  +------------------------------------------------------------+${NC}"
    
    echo -e "${NEON_CYAN}  // 📦 SYSTEM & TOOLCHAIN${NC}"
    echo -ne "  "; p_opt "2" "Base System + Mise Tools"; p_opt "3" "Dev Tools Only (Docker, GH)"; echo ""
    echo -ne "  "; p_opt "4" "Toolchain Sync (mise install)"; p_opt "5" "Update System (Force)"; echo ""
    echo -ne "  "; p_opt "6" "Install Base Packages"; echo ""
    
    echo -e "${NEON_CYAN}  // ☁️ CONFIG & CLOUD${NC}"
    echo -ne "  "; p_opt "7" "Configure Secrets"; p_opt "8" "Install AI Rules (Antigravity)"; echo ""
    echo -ne "  "; p_opt "9" "Configure Rclone"; p_opt "10" "SSH Keys Import"; echo ""
    echo -ne "  "; p_opt "11" "Install VSCode Extensions"; echo ""

    echo -e "${GRAY}  +------------------------------------------------------------+${NC}"
    echo -ne "  "; p_opt "0" "EXIT"; echo ""
    echo ""
    
    echo -ne "${NEON_GREEN}wrapper@install${NC}:${BLUE}~${NC}$ "
    read choice
    
    case $choice in
        1) install_all || handle_error $? "FULL_INSTALL" ;;
        2) install_system_all || handle_error $? "SYSTEM_INSTALL" ;;
        3) install_dev_tools_all || handle_error $? "DEV_TOOLS" ;;
        4) install_toolchain || handle_error $? "TOOLCHAIN_SYNC" ;;
        5) update_system --force || handle_error $? "SYSTEM_UPDATE" ;;
        6) install_packages || handle_error $? "PACKAGES" ;;
        7) decrypt_secrets || handle_error $? "SECRETS" ;;
        8) install_antigravity_full || handle_error $? "ANTIGRAVITY" ;;
        9) configure_rclone || handle_error $? "RCLONE" ;;
        10) install_ssh_keys || handle_error $? "SSH" ;;
        11) install_vscode_extensions || handle_error $? "EXTENSIONS" ;;
        0) exit 0 ;;
        *) echo -e "${RED}Invalid Option${NC}"; sleep 1 ;;
    esac
}

# --- MAIN ---
if [ "$1" == "--all" ]; then
    print_header "INITIATING HEADLESS DEPLOYMENT..."
    install_all
    exit 0
fi

chmod +x "$DOTFILES_DIR/scripts/"*.sh 2>/dev/null

while true; do
    show_menu
    read -r
done
