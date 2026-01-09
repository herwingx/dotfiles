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
    # Modo automático: instalar TODO sin preguntar
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

# --- ASCII ART PREMIUM ---
show_banner() {
    clear
    echo -e "${PURPLE}"
    # Fuente: ANSI Shadow (simplificada)
    cat << 'EOF'
  ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗ 
  ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██╔╝██║     ██╔════╝ 
  ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗   
  ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝   
  ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗ 
  ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝ 
EOF
    echo -e "${NC}"
    echo -e "                   ${DIM}v2.0 Premium Edition${NC}"
    echo -e "${BLUE}═════════════════════════════════════════════════════════${NC}"
    echo -e "      🚀 ${BOLD}ENVIRONMENT SETUP & AUTOMATION SUITE${NC} 🚀"
    echo -e "${BLUE}═════════════════════════════════════════════════════════${NC}"
    echo ""
}

# --- ERROR HANDLING ---
# Función para manejar errores con sugerencias
handle_error() {
    local exit_code=$1
    local task=$2
    if [ $exit_code -ne 0 ]; then
        echo ""
        print_error "Error crítico al ejecutar: ${BOLD}$task${NC}"
        echo -e "${YELLOW}  💡 Tips de solución:${NC}"
        echo -e "     • Verifica tu conexión a internet."
        echo -e "     • Asegúrate de tener permisos sudo."
        echo -e "     • Intenta: ${DIM}sudo apt update --fix-missing${NC}"
        echo ""
        read -p "  Presiona Enter para continuar (o Ctrl+C para salir)..."
    fi
}

# --- MENÚ INTERACTIVO ---
show_menu() {
    show_banner
    
    # helper para imprimir opción bonita
    # print_opt NUMERO DESCRIPCION
    print_opt() {
        echo -e "  ${PURPLE}│${NC}   ${GREEN}$1)${NC} $2"
    }
    
    echo -e "${PURPLE}  ┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}  │${NC}  ${BOLD}INSTALACIÓN PREFABS${NC}                                        ${PURPLE}│${NC}"
    echo -e "${PURPLE}  ├─────────────────────────────────────────────────────────────┤${NC}"
    print_opt "1" "⚡ ${BOLD}Full Stack${NC} (Sistema + Dev + AI + Cloud)             ${PURPLE}│${NC}"
    print_opt "2" "🖥️  ${BOLD}Solo Sistema${NC} (Bins + Git + SSH)                      ${PURPLE}│${NC}"
    print_opt "3" "🛠️  ${BOLD}Solo Dev Tools${NC} (NVM + Docker + GH CLI)              ${PURPLE}│${NC}"
    print_opt "4" "🤖 ${BOLD}Solo Antigravity${NC} (AI Rules + Workflows)             ${PURPLE}│${NC}"
    echo -e "${PURPLE}  ├─────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${PURPLE}  │${NC}  ${BOLD}MÓDULOS DE SISTEMA${NC}                                         ${PURPLE}│${NC}"
    echo -e "${PURPLE}  ├─────────────────────────────────────────────────────────────┤${NC}"
    print_opt "5" "📦 System Upgrade (apt/dnf update)                       ${PURPLE}│${NC}"
    print_opt "6" "🔧 Base Packages (lsd, fzf, bat, tmux, ble.sh)           ${PURPLE}│${NC}"
    print_opt "7" "⚙️  Git Config (Usuario + Alias)                          ${PURPLE}│${NC}"
    print_opt "8" "🔑 SSH Keys (Importar desde GitHub)                      ${PURPLE}│${NC}"
    print_opt "9" "🪟 WSL SSH Sync (Copiar desde Windows)                   ${PURPLE}│${NC}"
    echo -e "${PURPLE}  ├─────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${PURPLE}  │${NC}  ${BOLD}DEVELOPER TOOLS${NC}                                            ${PURPLE}│${NC}"
    echo -e "${PURPLE}  ├─────────────────────────────────────────────────────────────┤${NC}"
    print_opt "10" "🐙 GitHub CLI (Login + Extensions)                       ${PURPLE}│${NC}"
    print_opt "11" "📗 Node.js (NVM + LTS Version)                           ${PURPLE}│${NC}"
    print_opt "12" "📦 NPM Globals (Dev utils)                               ${PURPLE}│${NC}"
    print_opt "13" "🐳 Docker Engine & Compose                               ${PURPLE}│${NC}"
    echo -e "${PURPLE}  ├─────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${PURPLE}  │${NC}  ${BOLD}ANTIGRAVITY & CLOUD${NC}                                        ${PURPLE}│${NC}"
    echo -e "${PURPLE}  ├─────────────────────────────────────────────────────────────┤${NC}"
    print_opt "14" "📜 Ruleset (GEMINI.md)                                   ${PURPLE}│${NC}"
    print_opt "15" "🔄 Workflows (AI Slash Commands)                         ${PURPLE}│${NC}"
    print_opt "20" "🧠 Settings (Gemini Token + Secrets)                     ${PURPLE}│${NC}"
    print_opt "16" "☁️  Rclone (Gdrive Sync)                                 ${PURPLE}│${NC}"
    echo -e "${PURPLE}  ├─────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${PURPLE}  │${NC}  ${BOLD}MANTENIMIENTO${NC}                                              ${PURPLE}│${NC}"
    echo -e "${PURPLE}  ├─────────────────────────────────────────────────────────────┤${NC}"
    print_opt "17" "⏰ Activar Auto-Update (Cron + Telegram Bot)             ${PURPLE}│${NC}"
    print_opt "18" "🔄 Ejecutar Update Manual                                ${PURPLE}│${NC}"
    print_opt "19" "🗑️  Desinstalar Auto-Update                              ${PURPLE}│${NC}"
    echo -e "${PURPLE}  ├─────────────────────────────────────────────────────────────┤${NC}"
    print_opt "0" "🚪 ${RED}Salir${NC}                                                    ${PURPLE}│${NC}"
    echo -e "${PURPLE}  └─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -ne "${BOLD}  CMD${NC} ${BLUE}➜${NC} "
    read choice
    
    case $choice in
        1) install_all || handle_error $? "Instalación completa" ;;
        2) install_system_all || handle_error $? "Instalación de sistema" ;;
        3) install_dev_tools_all || handle_error $? "Instalación de Dev Tools" ;;
        4) install_antigravity_full || handle_error $? "Instalación de Antigravity AI" ;;
        5) update_system || handle_error $? "Actualización de sistema" ;;
        6) install_packages || handle_error $? "Instalación de paquetes" ;;
        7) install_gitconfig || handle_error $? "Configuración de Git" ;;
        8) install_ssh_keys || handle_error $? "Configuración de SSH" ;;
        9) copy_ssh_from_windows || handle_error $? "Copiado de SSH desde Windows" ;;
        10) install_gh_cli || handle_error $? "Instalación de GitHub CLI" ;;
        11) install_nvm_node || handle_error $? "Instalación de Node.js" ;;
        12) install_npm_global_packages || handle_error $? "Instalación de paquetes NPM" ;;
        13) install_docker || handle_error $? "Instalación de Docker" ;;
        14) install_antigravity_rules || handle_error $? "Instalación de reglas IA" ;;
        15) install_antigravity_workflows || handle_error $? "Instalación de workflows IA" ;;
        16) configure_rclone || handle_error $? "Configuración de rclone" ;;
        17) install_auto_update || handle_error $? "Configuración de auto-update" ;;
        18) run_manual_update || handle_error $? "Actualización manual" ;;
        19) uninstall_auto_update || handle_error $? "Desinstalación de auto-update" ;;
        20) install_gemini_settings || handle_error $? "Configuración de Gemini" ;;
        0)
            echo ""
            echo -e "${GREEN}  ✨ ¡Happy Coding! ✨${NC}"
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
    print_header "Iniciando instalación automática..."
    install_all
    exit 0
fi

while true; do
    show_menu
    
    echo ""
    echo -e "${DIM}  Presiona Enter para continuar...${NC}"
    read -r
done