#!/bin/bash
# ==============================================================================
# INSTALADOR DE DOTFILES v3.0 (PROTON PASS + MISE + UBUNTU/FEDORA)
# Orquestador interactivo e idempotente en español para Web Dev y Servidores
# ==============================================================================

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(dirname "$SCRIPT_PATH")"

# --- CARGAR MÓDULOS ---
# shellcheck disable=SC1091
source "$DOTFILES_DIR/scripts/common.sh"
# shellcheck disable=SC1091
source "$DOTFILES_DIR/scripts/system.sh"
# shellcheck disable=SC1091
source "$DOTFILES_DIR/scripts/git.sh"
# shellcheck disable=SC1091
source "$DOTFILES_DIR/scripts/toolchain.sh"
# shellcheck disable=SC1091
source "$DOTFILES_DIR/scripts/dev-tools.sh"
# shellcheck disable=SC1091
source "$DOTFILES_DIR/scripts/cloud.sh"
# shellcheck disable=SC1091
source "$DOTFILES_DIR/scripts/extensions.sh"
# shellcheck disable=SC1091
source "$DOTFILES_DIR/scripts/cron-update.sh"

# ─────────────────────────────────────────────────────────────
# 1. Instalación Completa Inteligente (Detecta Escritorio vs Servidor vs WSL)
# ─────────────────────────────────────────────────────────────
install_all() {
    export AUTO_INSTALL=true
    print_header "INSTALACIÓN COMPLETA INTELIGENTE :: ${OS_PRETTY_NAME}"

    update_system
    install_packages
    install_toolchain
    install_gitconfig
    install_ssh_keys
    configure_ssh_agent

    load_secrets
    configure_rclone
    install_dev_tools_all

    if [ "$IS_DESKTOP" == "true" ] || [ "$IS_WSL" == "true" ]; then
        install_vscode_extensions
    fi

    if [ "$IS_SERVER" == "true" ]; then
        install_auto_update
    fi

    show_reload_message
}

# ─────────────────────────────────────────────────────────────
# Perfil Servidor (Ubuntu Server / Fedora Server / Proxmox LXC)
# ─────────────────────────────────────────────────────────────
install_server_profile() {
    export AUTO_INSTALL=true
    IS_SERVER=true
    IS_DESKTOP=false
    ENV_PROFILE="server"
    ENV_PROFILE_LABEL="SERVIDOR (Headless)"

    print_header "INSTALACIÓN MODO SERVIDOR :: ${OS_PRETTY_NAME}"
    update_system
    install_packages
    install_toolchain
    install_gitconfig
    install_ssh_keys
    configure_ssh_agent
    load_secrets
    configure_rclone
    install_dev_tools_all
    install_auto_update
    show_reload_message
}

# ─────────────────────────────────────────────────────────────
# Perfil Escritorio / Workstation (Ubuntu Desktop / Fedora Workstation)
# ─────────────────────────────────────────────────────────────
install_desktop_profile() {
    export AUTO_INSTALL=true
    IS_DESKTOP=true
    IS_SERVER=false
    ENV_PROFILE="desktop"
    ENV_PROFILE_LABEL="ESCRITORIO (${SESSION_DISPLAY_TYPE})"

    print_header "INSTALACIÓN MODO ESCRITORIO :: ${OS_PRETTY_NAME}"
    update_system
    install_packages
    install_toolchain
    install_gitconfig
    install_ssh_keys
    configure_ssh_agent
    load_secrets
    configure_rclone
    install_dev_tools_all
    install_vscode_extensions
    show_reload_message
}

# ─────────────────────────────────────────────────────────────
# Instalación Personalizada por Módulos (Selección Múltiple)
# ─────────────────────────────────────────────────────────────
install_custom_multiselect() {
    print_header "INSTALACIÓN PERSONALIZADA POR MÓDULOS"

    local c_update="1. Actualizar Sistema Operativo (apt / dnf)"
    local c_pkgs="2. Paquetes Base + Aliases + Tmux + FZF + Zoxide + Oh My Posh"
    local c_mise="3. Toolchain Desarrollo Web (Mise: Node, pnpm, Bun, Go, Rust, Python, CLI)"
    local c_git="4. Configurar Git + Visor Delta + Agente SSH"
    local c_pass="5. Sincronizar Secretos desde Proton Pass CLI"
    local c_docker="6. Instalar Docker Engine + Compose y GitHub CLI"
    local c_rclone="7. Configurar Google Drive (Rclone)"
    local c_vscode="8. Instalar Extensiones de VS Code / Cursor"
    local c_cron="9. Activar Actualizaciones Automáticas Nocturnas (Cron + Telegram)"

    local selected
    selected=$(ui_choose_multi "Marca con ESPACIO los módulos que quieras instalar:" \
        "$c_update" "$c_pkgs" "$c_mise" "$c_git" "$c_pass" "$c_docker" "$c_rclone" "$c_vscode" "$c_cron") || return 0

    [ -z "$selected" ] && return 0

    while IFS= read -r item; do
        case "$item" in
            "$c_update") update_system --force ;;
            "$c_pkgs")   install_packages ;;
            "$c_mise")   install_toolchain ;;
            "$c_git")    install_gitconfig; install_ssh_keys; configure_ssh_agent ;;
            "$c_pass")   "$DOTFILES_DIR/scripts/manage_secrets.sh" pull ;;
            "$c_docker") install_dev_tools_all ;;
            "$c_rclone") configure_rclone ;;
            "$c_vscode") install_vscode_extensions ;;
            "$c_cron")   install_auto_update ;;
        esac
    done <<< "$selected"

    print_success "Todos los módulos seleccionados finalizaron correctamente."
}

show_reload_message() {
    print_header "Instalación Completada con Éxito"
    echo -e "${NEON_GREEN}  ✓ Tu entorno está listo en ${OS_PRETTY_NAME} (${ENV_PROFILE_LABEL})${NC}"
    if [ "${GUEST_MODE:-}" == "true" ]; then
        echo -e "${YELLOW}  ℹ Usaste el Modo Invitado: cuando quieras conectar Proton Pass,${NC}"
        echo -e "${YELLOW}    ejecuta: ${WHITE}./install.sh --secrets${NC}"
    fi
    echo -e "${GREEN}  Recargando tu terminal para aplicar todos los cambios... 🚀${NC}"
    echo ""
    if [ -t 0 ]; then
        exec bash
    fi
}

show_banner() {
    clear
    load_pass_config

    local mise_status="${YELLOW}Pendiente de instalar${NC}"
    if command -v mise &>/dev/null; then
        mise_status="${NEON_GREEN}Activo (Mise $(mise --version 2>/dev/null | awk '{print $1}'))${NC}"
    fi

    local pass_status="${YELLOW}Sin sesión (Modo Invitado disponible)${NC}"
    if pass_is_logged_in; then
        pass_status="${NEON_GREEN}Conectado (pass://${PROTON_PASS_VAULT}/${PROTON_PASS_ITEM})${NC}"
    elif [ -f "$LOCAL_STAGED_SECRETS" ]; then
        pass_status="${NEON_CYAN}Secretos locales listos para subir (Opción 9)${NC}"
    fi

    echo -e "${NEON_GREEN}"
    cat << 'EOF'
   ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
   ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
   ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
   ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
   ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
   ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
EOF
    echo -e "        ${NEON_CYAN}${NC}"
    echo ""
    echo -e "  ${NEON_CYAN}╭────────────────────────── ESTADO DEL SISTEMA ──────────────────────────╮${NC}"
    echo -e "  ${NEON_CYAN}│${NC}  ${NEON_GREEN}▸${NC} ${WHITE}Equipo y SO   :${NC} ${NEON_CYAN}$(uname -n)${NC} ${GRAY}(${OS_PRETTY_NAME})${NC}"
    echo -e "  ${NEON_CYAN}│${NC}  ${NEON_GREEN}▸${NC} ${WHITE}Perfil Activo :${NC} ${NEON_GREEN}${ENV_PROFILE_LABEL}${NC} ${GRAY}(Gestor: ${PKG_MANAGER})${NC}"
    echo -e "  ${NEON_CYAN}│${NC}  ${NEON_GREEN}▸${NC} ${WHITE}Toolchain     :${NC} ${mise_status}"
    echo -e "  ${NEON_CYAN}│${NC}  ${NEON_GREEN}▸${NC} ${WHITE}Proton Pass   :${NC} ${pass_status}"
    echo -e "  ${NEON_CYAN}╰────────────────────────────────────────────────────────────────────────╯${NC}"
    echo ""
}

handle_error() {
    local exit_code=$1
    local task=$2
    if [ "$exit_code" -ne 0 ]; then
        echo ""
        print_error "FALLÓ LA TAREA :: ${BOLD}$task${NC} (código: $exit_code)"
        echo -e "${YELLOW}  [DIAGNÓSTICO]:${NC}"
        echo -e "   • Verifica tu conexión a Internet"
        echo -e "   • Verifica tus permisos de administrador (sudo $PKG_MANAGER)"
        echo ""
        read -r -p "  [Presiona ENTER para continuar]..." </dev/tty
    fi
}

show_menu() {
    show_banner

    echo -e "  ${NEON_GREEN}🚀 DESPLIEGUE RÁPIDO (PERFILES AUTOMÁTICOS)${NC}"
    echo -e "  ${GRAY}──────────────────────────────────────────────────────────────────────────${NC}"
    p_menu_item "1" "Instalación Completa Inteligente"  "Instala todo según tu sistema (${ENV_PROFILE^^})"
    p_menu_item "2" "Instalación Personalizada"         "Elige paso a paso qué componentes instalar"
    p_menu_item "3" "Instalar Modo Servidor"            "Ideal para Ubuntu/Fedora Server o Proxmox LXC"
    p_menu_item "4" "Instalar Modo Escritorio"          "Incluye fuentes Nerd Font y extensiones del IDE"
    echo ""

    echo -e "  ${NEON_CYAN}📦 SISTEMA BASE Y HERRAMIENTAS DE DESARROLLO WEB${NC}"
    echo -e "  ${GRAY}──────────────────────────────────────────────────────────────────────────${NC}"
    p_menu_item "5" "Sincronizar Toolchain Web (Mise)"  "Node, pnpm, Bun, Python, Go, Rust, Lazygit y CLI"
    p_menu_item "6" "Paquetes Base y Terminal"          "Git, Tmux, Aliases, FZF, Zoxide y Oh My Posh"
    p_menu_item "7" "Instalar Docker y GitHub CLI"      "Docker Engine + Compose y utilidad oficial 'gh'"
    p_menu_item "8" "Actualizar Sistema Operativo"      "Ejecuta actualización completa (${PKG_MANAGER} upgrade)"
    echo ""

    echo -e "  ${NEON_CYAN}🔐 PROTON PASS, NUBE Y EDITOR DE CÓDIGO${NC}"
    echo -e "  ${GRAY}──────────────────────────────────────────────────────────────────────────${NC}"
    p_menu_item "9"  "Gestor de Secretos (Proton Pass)"  "Inicia sesión, sube o descarga tu nota '${PROTON_PASS_ITEM}'"
    p_menu_item "10" "Sincronizar Cuentas Cloud"         "Configura GitHub CLI, Google Drive (Rclone) y Telegram"
    p_menu_item "11" "Configurar Llaves y Agente SSH"    "Importar de Proton Pass, GitHub, WSL o crear nueva"
    p_menu_item "12" "Extensiones de VS Code / Cursor"   "Instala las extensiones de .vscode-extensions"
    echo -e "  ${GRAY}──────────────────────────────────────────────────────────────────────────${NC}"
    p_menu_item "0"  "Salir del Instalador"              "Volver a la terminal"
    echo ""

    local choice
    echo -ne "  ${NEON_GREEN}❯${NC} ${WHITE}Selecciona una opción [0-12]: ${NC}"
    if [ -t 0 ]; then
        read -r choice </dev/tty
    else
        read -r choice || choice="0"
    fi

    case "$choice" in
        1)  install_all || handle_error $? "INSTALACION_COMPLETA" ;;
        2)  install_custom_multiselect || handle_error $? "INSTALACION_PERSONALIZADA" ;;
        3)  install_server_profile || handle_error $? "MODO_SERVIDOR" ;;
        4)  install_desktop_profile || handle_error $? "MODO_ESCRITORIO" ;;
        5)  install_toolchain || handle_error $? "TOOLCHAIN_MISE" ;;
        6)  install_packages || handle_error $? "PAQUETES_BASE" ;;
        7)  install_dev_tools_all || handle_error $? "DOCKER_Y_GH" ;;
        8)  update_system --force || handle_error $? "ACTUALIZAR_SISTEMA" ;;
        9)  "$DOTFILES_DIR/scripts/manage_secrets.sh" ;;
        10) "$DOTFILES_DIR/scripts/manage_secrets.sh" pull && configure_rclone && gh_auth_login ;;
        11) setup_ssh_interactive || handle_error $? "CONFIGURAR_SSH" ;;
        12) install_vscode_extensions || handle_error $? "EXTENSIONES_IDE" ;;
        0|q|exit) echo ""; exit 0 ;;
        *) print_error "Opción no válida. Elige un número del 0 al 12."; sleep 1 ;;
    esac
}

show_help() {
    cat <<EOF
Instalador de Dotfiles v3.0 (Ubuntu & Fedora Server/Desktop + Mise + Proton Pass)

Uso:
  ./install.sh              Abre el menú interactivo en español
  ./install.sh --all        Instalación completa inteligente (auto-detecta Escritorio/Servidor/WSL)
  ./install.sh --guest      Instalación completa sin pedir credenciales (ideal para distros nuevas)
  ./install.sh --server     Instalación perfil Servidor (Headless + Docker + Auto-Updates Cron)
  ./install.sh --desktop    Instalación perfil Escritorio (Workstation + Fuentes + Extensiones IDE)
  ./install.sh --secrets    Abre el gestor de secretos de Proton Pass CLI
  ./install.sh --help       Muestra esta ayuda
EOF
}

# --- MAIN ROUTER ---
chmod +x "$DOTFILES_DIR/scripts/"*.sh 2>/dev/null || true

case "${1:-}" in
    --all)
        install_all
        exit 0
        ;;
    --guest)
        export GUEST_MODE=true
        install_all
        exit 0
        ;;
    --server)
        install_server_profile
        exit 0
        ;;
    --desktop)
        install_desktop_profile
        exit 0
        ;;
    --secrets|secrets)
        exec "$DOTFILES_DIR/scripts/manage_secrets.sh" "${@:2}"
        ;;
    --help|-h)
        show_help
        exit 0
        ;;
esac

while true; do
    show_menu
    echo ""
    read -r -p "  [Presiona ENTER para volver al menú principal]..." </dev/tty
done
