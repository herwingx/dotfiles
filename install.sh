#!/bin/bash
# ==========================================
# SCRIPT DE INSTALACIÓN (herwingx)
# Con menú interactivo para seleccionar módulos
# ==========================================

DOTFILES_DIR=$(pwd)

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
}

# --- MENÚ INTERACTIVO ---
show_menu() {
    clear
    echo -e "${CYAN}"
    echo -e "╔════════════════════════════════════════════════════════════════╗"
    echo -e "║            🚀 DOTFILES INSTALLER - herwingx 🚀                 ║"
    echo -e "╠════════════════════════════════════════════════════════════════╣"
    echo -e "║                                                                ║"
    echo -e "║  ${BOLD}INSTALACIÓN COMPLETA${NC}${CYAN}                                          ║"
    echo -e "║   1) Instalar TODO (sistema + dev tools + antigravity)         ║"
    echo -e "║   2) Solo Sistema (update, paquetes, tools, aliases, git, ssh) ║"
    echo -e "║   3) Solo Dev Tools (gh, nvm, docker)                          ║"
    echo -e "║   4) Solo Antigravity (reglas + workflows)                     ║"
    echo -e "║                                                                ║"
    echo -e "║  ${BOLD}SISTEMA (individual)${NC}${CYAN}                                          ║"
    echo -e "║   5) Actualizar sistema (apt/dnf upgrade)                      ║"
    echo -e "║   6) Paquetes + Tools + Aliases (fzf, lsd, tmux, ranger...)    ║"
    echo -e "║   7) Git Config                                                ║"
    echo -e "║   8) SSH Keys (importar desde GitHub)                          ║"
    echo -e "║   9) Copiar SSH desde Windows (solo WSL)                       ║"
    echo -e "║                                                                ║"
    echo -e "║  ${BOLD}DEV TOOLS (individual)${NC}${CYAN}                                        ║"
    echo -e "║  10) GitHub CLI (gh + auth con Bitwarden)                      ║"
    echo -e "║  11) NVM + Node.js LTS                                         ║"
    echo -e "║  12) npm packages (bitwarden-cli, claude-code)                 ║"
    echo -e "║  13) Docker + Docker Compose                                   ║"
    echo -e "║                                                                ║"
    echo -e "║  ${BOLD}ANTIGRAVITY (individual)${NC}${CYAN}                                      ║"
    echo -e "║  14) Solo Reglas (GEMINI.md)                                   ║"
    echo -e "║  15) Solo Workflows (/commit, /publicar, etc.)                 ║"
    echo -e "║                                                                ║"
    echo -e "║  ${BOLD}CLOUD${NC}${CYAN}                                                        ║"
    echo -e "║  16) Configurar rclone (Google Drive)                          ║"
    echo -e "║                                                                ║"
    echo -e "║   0) Salir                                                     ║"
    echo -e "║                                                                ║"
    echo -e "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    read -p "Selecciona una opción [0-16]: " choice
    
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
        16)
            configure_rclone
            ;;
        0)
            echo -e "${GREEN}>>> ¡Hasta luego!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}>>> Opción inválida${NC}"
            sleep 1
            ;;
    esac
}

# --- MAIN ---
while true; do
    show_menu
    
    echo ""
    echo -e "${CYAN}   Presiona Enter para volver al menú...${NC}"
    read -r
done