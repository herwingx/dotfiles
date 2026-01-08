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

# --- ASCII ART ---
show_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
    ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
    ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
    ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
    ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
    ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
    ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
EOF
    echo -e "${NC}"
    echo -e "${YELLOW}    ════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}                    🚀 LINUX ENVIRONMENT INSTALLER 🚀${NC}"
    echo -e "${YELLOW}    ════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# --- MENÚ INTERACTIVO ---
show_menu() {
    clear
    show_banner
    
    echo -e "${CYAN}  ┌──────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}  │${NC}  ${BOLD}INSTALACIÓN RÁPIDA${NC}                                          ${CYAN}│${NC}"
    echo -e "${CYAN}  ├──────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}  │${NC}   ${GREEN}1)${NC} ⚡ Instalar TODO (sistema + dev + IA + cloud)             ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}   ${GREEN}2)${NC} 🖥️  Solo Sistema (packages + tools + git + ssh)           ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}   ${GREEN}3)${NC} 🛠️  Solo Dev Tools (gh, nvm, docker)                       ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}   ${GREEN}4)${NC} 🤖 Solo Antigravity (reglas IA + workflows)               ${CYAN}│${NC}"
    echo -e "${CYAN}  ├──────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}  │${NC}  ${BOLD}SISTEMA${NC}                                                       ${CYAN}│${NC}"
    echo -e "${CYAN}  ├──────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}  │${NC}   ${GREEN}5)${NC} 📦 Actualizar sistema (apt/dnf/pacman upgrade)            ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}   ${GREEN}6)${NC} 🔧 Paquetes base + herramientas (lsd, fzf, tmux...)       ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}   ${GREEN}7)${NC} ⚙️  Git Config (configuración global)                      ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}   ${GREEN}8)${NC} 🔑 SSH Keys (importar desde GitHub)                       ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}   ${GREEN}9)${NC} 🪟 Copiar SSH desde Windows (solo WSL)                    ${CYAN}│${NC}"
    echo -e "${CYAN}  ├──────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}  │${NC}  ${BOLD}DEV TOOLS${NC}                                                     ${CYAN}│${NC}"
    echo -e "${CYAN}  ├──────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}  │${NC}  ${GREEN}10)${NC} 🐙 GitHub CLI (gh + auth con Bitwarden)                   ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}  ${GREEN}11)${NC} 📗 NVM + Node.js LTS                                      ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}  ${GREEN}12)${NC} 📦 npm packages (bw-cli, claude-code)                     ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}  ${GREEN}13)${NC} 🐳 Docker + Docker Compose                                ${CYAN}│${NC}"
    echo -e "${CYAN}  ├──────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}  │${NC}  ${BOLD}ANTIGRAVITY AI${NC}                                                ${CYAN}│${NC}"
    echo -e "${CYAN}  ├──────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}  │${NC}   ${GREEN}14)${NC} 📜 Solo Reglas (GEMINI.md)                                ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}   ${GREEN}15)${NC} 🔄 Solo Workflows (/commit, /publicar, etc.)              ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}   ${GREEN}20)${NC} ⚙️  Solo Settings (settings.json + Token)                  ${CYAN}│${NC}"
    echo -e "${CYAN}  ├──────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}  │${NC}  ${BOLD}CLOUD & MANTENIMIENTO${NC}                                         ${CYAN}│${NC}"
    echo -e "${CYAN}  ├──────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}  │${NC}  ${GREEN}16)${NC} ☁️  Configurar rclone (Google Drive)                       ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}  ${GREEN}17)${NC} ⏰ Configurar Auto-Update (cronjob + Telegram)            ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}  ${GREEN}18)${NC} 🔄 Ejecutar actualización manual                          ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}  ${GREEN}19)${NC} 🗑️  Desinstalar Auto-Update                                ${CYAN}│${NC}"
    echo -e "${CYAN}  ├──────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}  │${NC}   ${RED}0)${NC} 🚪 Salir                                                  ${CYAN}│${NC}"
    echo -e "${CYAN}  └──────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    read -p "  Selecciona una opción [0-19]: " choice
    
    case $choice in
        1)
            install_all
            ;;
        2)
            install_system_all
            ;;
        3)
            install_dev_tools_all
            ;;
        4)
            install_antigravity_full
            ;;
        5)
            update_system
            ;;
        6)
            install_packages
            ;;
        7)
            install_gitconfig
            ;;
        8)
            install_ssh_keys
            ;;
        9)
            copy_ssh_from_windows
            ;;
        10)
            install_gh_cli
            ;;
        11)
            install_nvm_node
            ;;
        12)
            install_npm_global_packages
            ;;
        13)
            install_docker
            ;;
        14)
            install_antigravity_rules
            ;;
        15)
            install_antigravity_workflows
            ;;
        20)
            install_gemini_settings
            ;;
        16)
            configure_rclone
            ;;
        17)
            install_auto_update
            ;;
        18)
            run_manual_update
            ;;
        19)
            uninstall_auto_update
            ;;
        0)
            echo ""
            echo -e "${GREEN}  ✨ ¡Hasta luego! ✨${NC}"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}  ✗ Opción inválida${NC}"
            sleep 1
            ;;
    esac
}

# --- MAIN ---

# Soporte para ejecución no interactiva (argumento --all)
if [ "$1" == "--all" ]; then
    echo -e "${GREEN}>>> Ejecutando instalación completa automática...${NC}"
    install_all
    exit 0
fi

while true; do
    show_menu
    
    echo ""
    echo -e "${CYAN}  ────────────────────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}  Presiona ${BOLD}Enter${NC}${CYAN} para volver al menú...${NC}"
    read -r
done