#!/bin/bash
# ==============================================================================
# DESINSTALADOR INTEGRAL DE DOTFILES v3.0 (ROBUST MODE)
# Soporta: Ubuntu/Debian y Fedora/RHEL (Server, Desktop y WSL)
# Incluye: Limpieza de .bashrc, .profile, cronjobs, Mise, Proton Pass CLI, Docker
# ==============================================================================

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

if [ -f "$SCRIPT_DIR/scripts/common.sh" ]; then
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/scripts/common.sh"
else
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    GRAY='\033[1;30m'
    NC='\033[0m'
    print_header() { echo -e "\n${CYAN}=== $1 ===${NC}\n"; }
    print_success() { echo -e "${GREEN}  ✓ $1${NC}"; }
    print_warning() { echo -e "${YELLOW}  ! $1${NC}"; }
    print_error() { echo -e "${RED}  ✗ $1${NC}"; }
fi

detect_os() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        case "$ID" in
            debian|ubuntu|linuxmint|pop)
                OS="debian"
                PKG_REMOVE="sudo apt-get purge -y"
                PKG_AUTOREMOVE="sudo apt-get autoremove -y"
                ;;
            fedora|rhel|centos|almalinux|rocky)
                OS="fedora"
                PKG_REMOVE="sudo dnf remove -y"
                PKG_AUTOREMOVE="sudo dnf autoremove -y"
                ;;
            *)
                OS="unknown"
                PKG_REMOVE="echo 'Sistema no soportado, elimina manualmente:'"
                PKG_AUTOREMOVE="true"
                ;;
        esac
    fi
}

show_danger_banner() {
    clear
    echo -e "${RED}"
    cat << 'EOF'
  ██████╗  █████╗ ███╗   ██╗ ██████╗ ███████╗██████╗ 
  ██╔══██╗██╔══██╗████╗  ██║██╔════╝ ██╔════╝██╔══██╗
  ██║  ██║███████║██╔██╗ ██║██║  ███╗█████╗  ██████╔╝
  ██║  ██║██╔══██║██║╚██╗██║██║   ██║██╔══╝  ██╔══██╗
  ██████╔╝██║  ██║██║ ╚████║╚██████╔╝███████╗██║  ██║
  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝
                    ZONE // UNINSTALLER v3.0
EOF
    echo -e "${NC}"
    echo -e "${RED}  ⚠️  ADVERTENCIA: Estás a punto de revertir tu entorno de desarrollo.${NC}"
    echo -e "${GRAY}  ────────────────────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}  • Configuraciones Shell${NC} (.bashrc blocks, aliases, gitconfig, tmux)"
    echo -e "${YELLOW}  • Toolchain Mise${NC} (Node, pnpm, Bun, Go, Rust, Python, CLI tools)"
    echo -e "${YELLOW}  • Proton Pass CLI${NC} (sesión local y binario pass-cli)"
    echo -e "${YELLOW}  • Cronjobs${NC} (auto-updates)"
    echo -e "${YELLOW}  • [OPCIONAL] Docker & Paquetes base${NC}"
    echo ""
}

show_uninstall_menu() {
    echo -e "${GRAY}  ────────────────────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}  Selecciona el modo de desinstalación:${NC}"
    echo ""
    echo -e "  ${GRAY}[${WHITE}1${GRAY}]${NC} 🔥 FULL DESTROY - Elimina TODO (reset total)"
    echo -e "  ${GRAY}[${WHITE}2${GRAY}]${NC} 🧹 LIMPIEZA SUAVE - Solo configs de dotfiles (mantiene Mise y Docker)"
    echo -e "  ${GRAY}[${WHITE}3${GRAY}]${NC} 🎯 SELECTIVO - Elige qué eliminar paso a paso"
    echo -e "  ${GRAY}[${WHITE}0${GRAY}]${NC} ❌ CANCELAR"
    echo ""
    echo -ne "${RED}  >> Opción: ${NC}"
    read -r UNINSTALL_MODE
}

clean_bashrc() {
    print_header "LIMPIANDO .bashrc Y PERFILES DE LOGIN"

    local bashrc="$HOME/.bashrc"
    if [ -f "$bashrc" ]; then
        cp "$bashrc" "$bashrc.uninstall_backup_$(date +%Y%m%d_%H%M%S)"
        print_success "Backup de .bashrc creado"

        local blocks=("MISE_SHIMS" "MISE" "WSL_PATH" "PATH_FIX" "GH_TOKEN" "ALIASES" "SSH_AGENT" "OH_MY_POSH" "FZF" "ZOXIDE" "NVM" "DOTFILES")
        for block in "${blocks[@]}"; do
            if grep -q "<!-- BEGIN_${block} -->" "$bashrc"; then
                sed -i "/<!-- BEGIN_${block} -->/,/<!-- END_${block} -->/d" "$bashrc"
                print_success "Bloque $block eliminado de .bashrc"
            fi
        done

        sed -i '/^$/N;/^\n$/d' "$bashrc"
    fi

    local profiles=("$HOME/.profile" "$HOME/.bash_profile" "$HOME/.zprofile")
    for profile in "${profiles[@]}"; do
        if [ -f "$profile" ] && grep -q "# BEGIN_MISE_PROFILE" "$profile"; then
            sed -i '/# BEGIN_MISE_PROFILE/,/# END_MISE_PROFILE/d' "$profile"
            print_success "Bloque MISE_PROFILE eliminado de $(basename "$profile")"
        fi
    done
}

restore_backups() {
    print_header "RESTAURANDO BACKUPS"
    local restored=0
    for file in .bashrc .bash_aliases .gitconfig .tmux.conf; do
        if [ -f "$HOME/${file}.backup" ]; then
            mv "$HOME/${file}.backup" "$HOME/$file"
            print_success "$file restaurado desde backup"
            restored=$((restored + 1))
        fi
    done
    [ $restored -eq 0 ] && print_warning "No se encontraron backups previos para restaurar"
}

remove_dotfiles() {
    print_header "ELIMINANDO ARCHIVOS DE CONFIGURACIÓN"
    local files=(
        "$HOME/.bash_aliases"
        "$HOME/.gitconfig"
        "$HOME/.tmux.conf"
        "$HOME/.mise.toml"
        "$HOME/.config/mise/config.toml"
    )
    for file in "${files[@]}"; do
        if [ -f "$file" ] || [ -L "$file" ]; then
            rm -f "$file"
            print_success "Eliminado: $file"
        fi
    done
    rm -rf "$HOME/.cache/oh-my-posh" "$HOME/.poshthemes/herwingx.omp.json" 2>/dev/null || true
}

remove_cronjobs() {
    print_header "ELIMINANDO CRONJOBS"
    if command -v crontab &>/dev/null && crontab -l 2>/dev/null | grep -q "cron-update.sh"; then
        crontab -l 2>/dev/null | grep -v "cron-update.sh" | crontab -
        print_success "Cronjob de auto-update eliminado"
    else
        print_warning "No se encontraron cronjobs activos"
    fi
}

remove_mise() {
    print_header "ELIMINANDO MISE TOOLCHAIN"
    if command -v mise &> /dev/null || [ -d "$HOME/.local/share/mise" ]; then
        mise uninstall --all 2>/dev/null || true
        rm -f "$HOME/.local/bin/mise"
        rm -rf "$HOME/.local/share/mise" "$HOME/.config/mise" "$HOME/.cache/mise" "$HOME/.local/state/mise"
        print_success "Mise y todas sus herramientas eliminados"
    else
        print_warning "Mise no encontrado"
    fi
}

remove_pass_cli() {
    print_header "ELIMINANDO PROTON PASS CLI"
    if command -v pass-cli &>/dev/null || [ -d "$HOME/.local/share/proton-pass-cli" ]; then
        echo -ne "${YELLOW}  ¿Cerrar sesión y eliminar Proton Pass CLI local? [s/N]: ${NC}"
        read -r rm_pass
        if [[ "$rm_pass" =~ ^[SsYy]$ ]]; then
            pass-cli ssh-agent daemon stop 2>/dev/null || true
            pass-cli logout --force 2>/dev/null || true
            rm -f "$HOME/.local/bin/pass-cli"
            rm -f "$HOME/.local/share/bash-completion/completions/pass-cli"
            rm -rf "$HOME/.local/share/proton-pass-cli"
            print_success "Proton Pass CLI eliminado"
        fi
    fi
}

remove_docker() {
    if command -v docker &> /dev/null; then
        print_header "DOCKER DETECTADO"
        echo -e "${RED}  ⚠️  Esto eliminará todas las imágenes, contenedores y volúmenes.${NC}"
        echo -ne "${RED}  ¿Purgar Docker completamente? [s/N]: ${NC}"
        read -r rm_docker
        if [[ "$rm_docker" =~ ^[SsYy]$ ]]; then
            docker ps -aq | xargs -r docker stop 2>/dev/null || true
            docker ps -aq | xargs -r docker rm 2>/dev/null || true
            docker system prune -a --volumes -f 2>/dev/null || true
            case "$OS" in
                debian)
                    $PKG_REMOVE docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
                    sudo rm -rf /var/lib/docker /var/lib/containerd
                    ;;
                fedora)
                    $PKG_REMOVE docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
                    sudo rm -rf /var/lib/docker /var/lib/containerd
                    ;;
            esac
            sudo gpasswd -d "$USER" docker 2>/dev/null || true
            print_success "Docker purgado completamente"
        fi
    fi
}

remove_system_packages() {
    print_header "PAQUETES OPCIONALES DEL SISTEMA"
    echo -ne "${YELLOW}  ¿Eliminar paquetes extra (tmux, ranger, mc, tree)? [s/N]: ${NC}"
    read -r rm_pkgs
    if [[ "$rm_pkgs" =~ ^[SsYy]$ ]]; then
        $PKG_REMOVE tmux ranger mc tree 2>/dev/null || true
        $PKG_AUTOREMOVE 2>/dev/null || true
        print_success "Paquetes opcionales eliminados"
    fi
}

full_destroy() {
    echo ""
    echo -ne "${RED}  Escribe 'DESTROY' para confirmar: ${NC}"
    read -r confirm
    if [ "$confirm" != "DESTROY" ]; then
        print_warning "Desinstalación cancelada"
        exit 0
    fi
    clean_bashrc
    remove_cronjobs
    remove_dotfiles
    remove_mise
    remove_pass_cli
    remove_docker
    remove_system_packages
    restore_backups
}

soft_clean() {
    echo -ne "${YELLOW}  ¿Confirmar limpieza suave de configs? [s/N]: ${NC}"
    read -r confirm
    [[ ! "$confirm" =~ ^[SsYy]$ ]] && exit 0
    clean_bashrc
    remove_cronjobs
    remove_dotfiles
    restore_backups
}

selective_clean() {
    echo -ne "${YELLOW}  [1/6] ¿Limpiar .bashrc y perfiles (.profile)? [s/N]: ${NC}"; read -r q1; [[ "$q1" =~ ^[SsYy]$ ]] && clean_bashrc
    echo -ne "${YELLOW}  [2/6] ¿Eliminar cronjobs? [s/N]: ${NC}"; read -r q2; [[ "$q2" =~ ^[SsYy]$ ]] && remove_cronjobs
    echo -ne "${YELLOW}  [3/6] ¿Eliminar symlinks de dotfiles? [s/N]: ${NC}"; read -r q3; [[ "$q3" =~ ^[SsYy]$ ]] && remove_dotfiles
    echo -ne "${YELLOW}  [4/6] ¿Eliminar Mise Toolchain? [s/N]: ${NC}"; read -r q4; [[ "$q4" =~ ^[SsYy]$ ]] && remove_mise
    remove_pass_cli
    remove_docker
    echo -ne "${YELLOW}  [6/6] ¿Restaurar backups anteriores? [s/N]: ${NC}"; read -r q6; [[ "$q6" =~ ^[SsYy]$ ]] && restore_backups
}

detect_os
show_danger_banner
show_uninstall_menu

case "$UNINSTALL_MODE" in
    1) full_destroy ;;
    2) soft_clean ;;
    3) selective_clean ;;
    *)
        print_success "Desinstalación cancelada. Tu entorno está intacto."
        exit 0
        ;;
esac

print_header "DESINSTALACIÓN COMPLETADA"
echo -e "${GREEN}  Ejecuta 'exec bash' para recargar tu shell.${NC}"
