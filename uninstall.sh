#!/bin/bash
# ==============================================================================
# DESINSTALADOR INTEGRAL DE DOTFILES (ROBUST MODE)
# ==============================================================================
# Desinstalación completa y segura de todos los componentes instalados.
# Soporta: Debian/Ubuntu, Fedora/RHEL, Arch Linux
# Incluye: Limpieza de .bashrc, cronjobs, paquetes sistema, runtimes, Docker
# ==============================================================================

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Cargar colores y funciones comunes
if [ -f "$SCRIPT_DIR/scripts/common.sh" ]; then
    source "$SCRIPT_DIR/scripts/common.sh"
else
    # Colores básicos si no existe common.sh
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'
    print_header() { echo -e "\n${CYAN}=== $1 ===${NC}\n"; }
    print_success() { echo -e "${GREEN}  ✓ $1${NC}"; }
    print_warning() { echo -e "${YELLOW}  ! $1${NC}"; }
    print_error() { echo -e "${RED}  ✗ $1${NC}"; }
fi

# ─────────────────────────────────────────────────────────────
# Detecta sistema operativo para desinstalación
#
# Configura los comandos de eliminación y limpieza de paquetes
# según la distribución detectada.
# ─────────────────────────────────────────────────────────────
detect_os() {
    if [ -f /etc/os-release ]; then
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
            arch|manjaro|endeavouros)
                OS="arch"
                PKG_REMOVE="sudo pacman -Rns --noconfirm"
                PKG_AUTOREMOVE="true"
                ;;
            opensuse*|suse)
                OS="suse"
                PKG_REMOVE="sudo zypper remove -y"
                PKG_AUTOREMOVE="true"
                ;;
            alpine)
                OS="alpine"
                PKG_REMOVE="sudo apk del"
                PKG_AUTOREMOVE="true"
                ;;
            *)
                OS="unknown"
                PKG_REMOVE="echo 'Sistema no soportado, elimina manualmente:'"
                PKG_AUTOREMOVE="true"
                ;;
        esac
    else
        if [ -f /etc/debian_version ]; then
            OS="debian"
            PKG_REMOVE="sudo apt-get purge -y"
            PKG_AUTOREMOVE="sudo apt-get autoremove -y"
        elif [ -f /etc/redhat-release ]; then
            OS="fedora"
            PKG_REMOVE="sudo dnf remove -y"
            PKG_AUTOREMOVE="sudo dnf autoremove -y"
        elif [ -f /etc/arch-release ]; then
            OS="arch"
            PKG_REMOVE="sudo pacman -Rns --noconfirm"
            PKG_AUTOREMOVE="true"
        else
            OS="unknown"
            PKG_REMOVE="echo 'Sistema no soportado, elimina manualmente:'"
            PKG_AUTOREMOVE="true"
        fi
    fi
}

# Banner de advertencia
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
                    ZONE // UNINSTALLER v2.0
EOF
    echo -e "${NC}"
    echo -e "${RED}  ⚠️  ADVERTENCIA: Estás a punto de DESTRUIR tu entorno de desarrollo.${NC}"
    echo -e "${GRAY}  ────────────────────────────────────────────────────────────────${NC}"
    echo -e "${RED}  Esta acción es IRREVERSIBLE y eliminará:${NC}"
    echo ""
    echo -e "${YELLOW}  • Configuraciones Shell${NC} (.bashrc patches, aliases, gitconfig)"
    echo -e "${YELLOW}  • Toolchain${NC} (Mise, Node, Go, Rust)"
    echo -e "${YELLOW}  • Binarios locales${NC} (oh-my-posh, zoxide, atuin, ble.sh)"
    echo -e "${YELLOW}  • Cronjobs${NC} (auto-updates)"
    echo -e "${YELLOW}  • [OPCIONAL] Docker${NC} (imágenes, contenedores, volúmenes)"
    echo -e "${YELLOW}  • [OPCIONAL] Paquetes sistema${NC} (fzf, ripgrep, gh, etc.)"
    echo ""
}

# Menú de selección
show_uninstall_menu() {
    echo -e "${GRAY}  ────────────────────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}  Selecciona el modo de desinstalación:${NC}"
    echo ""
    echo -e "  ${GRAY}[${WHITE}1${GRAY}]${NC} 🔥 FULL DESTROY - Elimina TODO (recomendado para reset total)"
    echo -e "  ${GRAY}[${WHITE}2${GRAY}]${NC} 🧹 LIMPIEZA SUAVE - Solo configs de dotfiles (mantiene runtimes)"
    echo -e "  ${GRAY}[${WHITE}3${GRAY}]${NC} 🎯 SELECTIVO - Elige qué eliminar"
    echo -e "  ${GRAY}[${WHITE}0${GRAY}]${NC} ❌ CANCELAR"
    echo ""
    echo -ne "${RED}  >> Opción: ${NC}"
    read UNINSTALL_MODE
}

# ─────────────────────────────────────────────────────────────────────────────
# FUNCIONES DE LIMPIEZA
# ─────────────────────────────────────────────────────────────────────────────

# Limpia .bashrc de todos los bloques gestionados
clean_bashrc() {
    print_header "LIMPIANDO .bashrc"
    
    BASHRC="$HOME/.bashrc"
    
    if [ ! -f "$BASHRC" ]; then
        print_warning ".bashrc no encontrado"
        return
    fi
    
    # Crear backup antes de modificar
    cp "$BASHRC" "$BASHRC.uninstall_backup_$(date +%Y%m%d_%H%M%S)"
    print_success "Backup creado"
    
    # 1. Eliminar bloques con formato <!-- BEGIN_* --> ... <!-- END_* -->
    BLOCKS=("MISE_SHIMS" "MISE" "WSL_PATH" "PATH_FIX" "GH_TOKEN" "ALIASES" "SSH_AGENT" "OH_MY_POSH" "FZF" "NVM" "DOTFILES")
    for block in "${BLOCKS[@]}"; do
        if grep -q "<!-- BEGIN_${block} -->" "$BASHRC"; then
            sed -i "/<!-- BEGIN_${block} -->/,/<!-- END_${block} -->/d" "$BASHRC"
            print_success "Bloque $block eliminado"
        fi
    done
    
    # 2. Eliminar bloques legacy (formato antiguo)
    sed -i '/# MANAGED BY DOTFILES/,/# END MANAGED BY DOTFILES/d' "$BASHRC" 2>/dev/null
    
    # 3. Eliminar líneas sueltas conocidas
    PATTERNS=(
        "oh-my-posh"
        "atuin"
        "ble.sh"
        "ble-attach"
        "NVM_DIR"
        "nvm.sh"
        "GITHUB_PERSONAL_ACCESS_TOKEN"
        "zoxide"
        "starship"
        "dotfiles/scripts"
        "mise activate"
        "mise/shims"
    )
    
    for pattern in "${PATTERNS[@]}"; do
        sed -i "/$pattern/d" "$BASHRC" 2>/dev/null
    done
    
    # 4. Limpiar líneas vacías múltiples consecutivas
    sed -i '/^$/N;/^\n$/d' "$BASHRC"
    
    # 5. Limpiar bloques MISE de perfiles de login
    PROFILES=("$HOME/.profile" "$HOME/.bash_profile" "$HOME/.zprofile")
    for profile in "${PROFILES[@]}"; do
        if [ -f "$profile" ] && grep -q "# BEGIN_MISE_PROFILE" "$profile"; then
            sed -i '/# BEGIN_MISE_PROFILE/,/# END_MISE_PROFILE/d' "$profile"
            print_success "Bloque MISE eliminado de $(basename "$profile")"
        fi
    done
    
    print_success ".bashrc y perfiles limpiados"
}

# Restaurar backups si existen
restore_backups() {
    print_header "RESTAURANDO BACKUPS"
    
    RESTORED=0
    
    for file in .bashrc .bash_aliases .gitconfig .tmux.conf; do
        if [ -f "$HOME/${file}.backup" ]; then
            mv "$HOME/${file}.backup" "$HOME/$file"
            print_success "$file restaurado desde backup"
            RESTORED=$((RESTORED + 1))
        fi
    done
    
    if [ $RESTORED -eq 0 ]; then
        print_warning "No se encontraron backups para restaurar"
    fi
}

# Eliminar symlinks y archivos de dotfiles
remove_dotfiles() {
    print_header "ELIMINANDO DOTFILES"
    
    FILES_TO_REMOVE=(
        "$HOME/.bash_aliases"
        "$HOME/.gitconfig"
        "$HOME/.tmux.conf"
        "$HOME/.inputrc"
        "$HOME/.mise.toml"
    )
    
    DIRS_TO_REMOVE=(
        "$HOME/.config/atuin"
        "$HOME/.cache/oh-my-posh"
    )
    
    for file in "${FILES_TO_REMOVE[@]}"; do
        if [ -f "$file" ] || [ -L "$file" ]; then
            rm -f "$file"
            print_success "Eliminado: $(basename $file)"
        fi
    done
    
    for dir in "${DIRS_TO_REMOVE[@]}"; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"
            print_success "Eliminado: $(basename $dir)/"
        fi
    done
}

# Eliminar cronjobs de dotfiles
remove_cronjobs() {
    print_header "ELIMINANDO CRONJOBS"
    
    # Verificar si hay cronjobs de dotfiles
    if crontab -l 2>/dev/null | grep -q "dotfiles"; then
        crontab -l 2>/dev/null | grep -v "dotfiles" | crontab -
        print_success "Cronjobs de auto-update eliminados"
    else
        print_warning "No se encontraron cronjobs de dotfiles"
    fi
    
    # Eliminar timer de systemd si existe
    if systemctl --user is-enabled dotfiles-update.timer 2>/dev/null; then
        systemctl --user disable --now dotfiles-update.timer 2>/dev/null
        rm -f "$HOME/.config/systemd/user/dotfiles-update.timer"
        rm -f "$HOME/.config/systemd/user/dotfiles-update.service"
        systemctl --user daemon-reload
        print_success "Timer de systemd eliminado"
    fi
}

# Eliminar Mise
remove_mise() {
    print_header "ELIMINANDO MISE TOOLCHAIN"
    
    if command -v mise &> /dev/null || [ -d "$HOME/.local/share/mise" ]; then
        # Desinstalar herramientas primero
        mise uninstall --all 2>/dev/null
        
        # Eliminar binario y datos
        rm -f "$HOME/.local/bin/mise"
        rm -rf "$HOME/.local/share/mise"
        rm -rf "$HOME/.config/mise"
        print_success "Mise y tools eliminados"
    else
        print_warning "Mise no encontrado"
    fi
}

# Eliminar NVM y Node.js (Legacy Cleanup)
remove_nvm() {
    if [ -d "$HOME/.nvm" ]; then
        print_header "ELIMINANDO NVM / NODE.JS (LEGACY)"
        rm -rf "$HOME/.nvm"
        rm -rf "$HOME/.npm"
        print_success "NVM y Node.js eliminados"
    fi
}

# Eliminar herramientas locales (oh-my-posh, zoxide, atuin, ble.sh)
remove_local_tools() {
    print_header "ELIMINANDO HERRAMIENTAS LOCALES"
    
    TOOLS=(
        "$HOME/.local/bin/oh-my-posh"
        "$HOME/.local/bin/zoxide"
        "$HOME/.local/bin/lsd"
        "$HOME/.local/bin/bat"
        "$HOME/.local/bin/fd"
        "$HOME/.local/bin/rg"
        "$HOME/.local/bin/eza"
        "$HOME/.local/bin/delta"
        "$HOME/.local/bin/starship"
    )
    
    TOOL_DIRS=(
        "$HOME/.local/share/blesh"
        "$HOME/.atuin"
        "$HOME/.local/share/atuin"
        "$HOME/.config/atuin"
        "$HOME/.cache/ble.sh"
    )
    
    for tool in "${TOOLS[@]}"; do
        if [ -f "$tool" ]; then
            rm -f "$tool"
            print_success "Eliminado: $(basename $tool)"
        fi
    done
    
    for dir in "${TOOL_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"
            print_success "Eliminado: $(basename $dir)/"
        fi
    done
}

# Eliminar Homebrew (Linux)
remove_homebrew() {
    if [ -d "/home/linuxbrew" ] || [ -d "$HOME/.linuxbrew" ]; then
        print_header "HOMEBREW DETECTADO"
        echo -ne "${YELLOW}  ¿Eliminar Homebrew? [s/N]: ${NC}"
        read RM_BREW
        if [[ "$RM_BREW" =~ ^[Ss]$ ]]; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)" 2>/dev/null
            sudo rm -rf /home/linuxbrew 2>/dev/null
            rm -rf "$HOME/.linuxbrew" 2>/dev/null
            print_success "Homebrew eliminado"
        else
            print_warning "Homebrew omitido"
        fi
    fi
}

# ─────────────────────────────────────────────────────────────
# Elimina Docker
#
# Detiene contenedores, elimina volúmenes y desinstala el paquete.
# ─────────────────────────────────────────────────────────────
remove_docker() {
    if command -v docker &> /dev/null; then
        print_header "DOCKER DETECTADO"
        echo -e "${RED}  ⚠️  Esto eliminará TODAS las imágenes, contenedores y volúmenes.${NC}"
        echo -ne "${RED}  ¿Purgar Docker completamente? [s/N]: ${NC}"
        read RM_DOCKER
        
        if [[ "$RM_DOCKER" =~ ^[Ss]$ ]]; then
            echo -e "${CYAN}  Deteniendo contenedores...${NC}"
            docker stop $(docker ps -aq) 2>/dev/null
            docker rm $(docker ps -aq) 2>/dev/null
            
            echo -e "${CYAN}  Eliminando imágenes y volúmenes...${NC}"
            docker system prune -a --volumes -f 2>/dev/null
            
            echo -e "${CYAN}  Desinstalando paquetes Docker...${NC}"
            case $OS in
                debian)
                    $PKG_REMOVE docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras 2>/dev/null
                    sudo rm -rf /var/lib/docker /var/lib/containerd
                    ;;
                fedora)
                    $PKG_REMOVE docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null
                    sudo rm -rf /var/lib/docker /var/lib/containerd
                    ;;
                arch)
                    $PKG_REMOVE docker docker-compose 2>/dev/null
                    sudo rm -rf /var/lib/docker
                    ;;
                suse)
                    $PKG_REMOVE docker docker-compose 2>/dev/null
                    sudo rm -rf /var/lib/docker
                    ;;
                alpine)
                    $PKG_REMOVE docker docker-cli-compose 2>/dev/null
                    sudo rm -rf /var/lib/docker
                    ;;
            esac
            
            # Eliminar grupo docker del usuario
            sudo gpasswd -d "$USER" docker 2>/dev/null
            
            print_success "Docker purgado completamente"
        else
            print_warning "Docker omitido"
        fi
    fi
}

# ─────────────────────────────────────────────────────────────
# Elimina GitHub CLI
# ─────────────────────────────────────────────────────────────
remove_gh_cli() {
    if command -v gh &> /dev/null; then
        print_header "GITHUB CLI"
        echo -ne "${YELLOW}  ¿Eliminar GitHub CLI (gh)? [s/N]: ${NC}"
        read RM_GH
        
        if [[ "$RM_GH" =~ ^[Ss]$ ]]; then
            case $OS in
                debian)
                    $PKG_REMOVE gh 2>/dev/null
                    sudo rm -f /etc/apt/sources.list.d/github-cli.list
                    sudo rm -f /usr/share/keyrings/githubcli-archive-keyring.gpg
                    ;;
                fedora)
                    $PKG_REMOVE gh 2>/dev/null
                    sudo rm -f /etc/yum.repos.d/gh-cli.repo
                    ;;
                arch)
                    $PKG_REMOVE github-cli 2>/dev/null
                    ;;
                suse)
                    $PKG_REMOVE gh 2>/dev/null
                    sudo zypper rr https://cli.github.com/packages/rpm/gh-cli.repo
                    ;;
                alpine)
                    $PKG_REMOVE github-cli 2>/dev/null
                    ;;
            esac
            
            # Logout de gh
            gh auth logout --hostname github.com 2>/dev/null
            rm -rf "$HOME/.config/gh"
            
            print_success "GitHub CLI eliminado"
        else
            print_warning "GitHub CLI omitido"
        fi
    fi
}

# ─────────────────────────────────────────────────────────────
# Eliminar paquetes base
# ─────────────────────────────────────────────────────────────
remove_system_packages() {
    print_header "PAQUETES DEL SISTEMA"
    echo -e "${YELLOW}  Estos son paquetes instalados por dotfiles que podrías querer mantener.${NC}"
    echo -ne "${YELLOW}  ¿Eliminar paquetes base (fzf, ripgrep, tmux, etc.)? [s/N]: ${NC}"
    read RM_PKGS
    
    if [[ "$RM_PKGS" =~ ^[Ss]$ ]]; then
        PACKAGES_TO_REMOVE="fzf ripgrep bat fd-find tmux neovim htop tree jq unzip wget curl"
        
        case $OS in
            debian)
                # En Debian, fd-find es el nombre del paquete
                $PKG_REMOVE $PACKAGES_TO_REMOVE 2>/dev/null
                ;;
            fedora)
                # En Fedora, fd es el nombre del paquete
                PACKAGES_TO_REMOVE=$(echo $PACKAGES_TO_REMOVE | sed 's/fd-find/fd/')
                $PKG_REMOVE $PACKAGES_TO_REMOVE 2>/dev/null
                ;;
            arch)
                $PKG_REMOVE fzf ripgrep bat fd tmux neovim htop tree jq unzip wget curl 2>/dev/null
                ;;
            suse)
                PACKAGES_TO_REMOVE=$(echo $PACKAGES_TO_REMOVE | sed 's/fd-find/fd/')
                $PKG_REMOVE $PACKAGES_TO_REMOVE 2>/dev/null
                ;;
            alpine)
                PACKAGES_TO_REMOVE=$(echo $PACKAGES_TO_REMOVE | sed 's/fd-find/fd/')
                $PKG_REMOVE $PACKAGES_TO_REMOVE 2>/dev/null
                ;;
        esac
        
        $PKG_AUTOREMOVE
        print_success "Paquetes del sistema eliminados"
    else
        print_warning "Paquetes del sistema omitidos"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# MODOS DE DESINSTALACIÓN
# ─────────────────────────────────────────────────────────────────────────────

# Modo FULL DESTROY
full_destroy() {
    echo ""
    echo -e "${RED}  ╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}  ║  MODO: FULL DESTROY - ÚLTIMA CONFIRMACIÓN                      ║${NC}"
    echo -e "${RED}  ╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -ne "${RED}  Escribe 'DESTROY' para confirmar: ${NC}"
    read CONFIRM
    
    if [ "$CONFIRM" != "DESTROY" ]; then
        print_warning "Desinstalación cancelada"
        exit 0
    fi
    
    echo ""
    
    clean_bashrc
    remove_cronjobs
    remove_dotfiles
    remove_mise
    remove_nvm
    remove_local_tools
    remove_homebrew
    remove_docker
    remove_gh_cli
    remove_system_packages
    restore_backups
}

# Modo LIMPIEZA SUAVE
soft_clean() {
    echo ""
    echo -e "${CYAN}  MODO: LIMPIEZA SUAVE${NC}"
    echo -e "${GRAY}  Solo se eliminarán configs, manteniendo runtimes instalados.${NC}"
    echo ""
    echo -ne "${YELLOW}  ¿Continuar? [s/N]: ${NC}"
    read CONFIRM
    
    if [[ ! "$CONFIRM" =~ ^[Ss]$ ]]; then
        print_warning "Desinstalación cancelada"
        exit 0
    fi
    
    clean_bashrc
    remove_cronjobs
    remove_dotfiles
    restore_backups
}

# Modo SELECTIVO
selective_clean() {
    echo ""
    echo -e "${CYAN}  MODO: SELECTIVO${NC}"
    echo -e "${GRAY}  Selecciona qué componentes eliminar.${NC}"
    echo ""
    
    echo -ne "${YELLOW}  [1/9] ¿Limpiar .bashrc? [s/N]: ${NC}"
    read Q1
    [[ "$Q1" =~ ^[Ss]$ ]] && clean_bashrc
    
    echo -ne "${YELLOW}  [2/9] ¿Eliminar cronjobs? [s/N]: ${NC}"
    read Q2
    [[ "$Q2" =~ ^[Ss]$ ]] && remove_cronjobs
    
    echo -ne "${YELLOW}  [3/9] ¿Eliminar dotfiles (aliases, gitconfig, tmux)? [s/N]: ${NC}"
    read Q3
    [[ "$Q3" =~ ^[Ss]$ ]] && remove_dotfiles
    
    echo -ne "${YELLOW}  [4/9] ¿Eliminar Mise Toolchain? [s/N]: ${NC}"
    read Q4
    [[ "$Q4" =~ ^[Ss]$ ]] && remove_mise
    
    echo -ne "${YELLOW}  [5/9] ¿Eliminar NVM/Node Legacy? [s/N]: ${NC}"
    read Q5
    [[ "$Q5" =~ ^[Ss]$ ]] && remove_nvm
    
    echo -ne "${YELLOW}  [6/9] ¿Eliminar herramientas locales (oh-my-posh, etc.)? [s/N]: ${NC}"
    read Q7
    [[ "$Q7" =~ ^[Ss]$ ]] && remove_local_tools
    
    remove_homebrew
    remove_docker
    remove_gh_cli
    
    echo -ne "${YELLOW}  [8/9] ¿Eliminar paquetes sistema (fzf, ripgrep, etc.)? [s/N]: ${NC}"
    read Q8
    [[ "$Q8" =~ ^[Ss]$ ]] && remove_system_packages
    
    echo -ne "${YELLOW}  [9/9] ¿Restaurar backups anteriores? [s/N]: ${NC}"
    read Q9
    [[ "$Q9" =~ ^[Ss]$ ]] && restore_backups

    echo -ne "${YELLOW}  [10/10] ¿Eliminar Ble.sh (Fix VSCode)? [s/N]: ${NC}"
    read Q10
    if [[ "$Q10" =~ ^[Ss]$ ]]; then
        rm -rf "$HOME/.local/share/blesh"
        rm -rf "$HOME/.cache/ble.sh"
        rm -f "$HOME/.blerc"
        sed -i '/ble.sh/d' "$HOME/.bashrc"
        sed -i '/ble-attach/d' "$HOME/.bashrc"
        print_success "Ble.sh eliminado"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

detect_os

show_danger_banner
show_uninstall_menu

case $UNINSTALL_MODE in
    1) full_destroy ;;
    2) soft_clean ;;
    3) selective_clean ;;
    0|*)
        echo ""
        print_success "Desinstalación cancelada. Tu entorno está intacto."
        exit 0
        ;;
esac

# Mensaje final
echo ""
print_header "DESINSTALACIÓN COMPLETADA"
echo -e "${GRAY}  ────────────────────────────────────────────────────────────────${NC}"
echo -e "${CYAN}  Tu entorno ha sido reseteado.${NC}"
echo ""
echo -e "${WHITE}  Siguiente paso:${NC}"
echo -e "${GREEN}    exec bash${NC}  (recarga tu shell)"
echo ""
echo -e "${GRAY}  Si deseas reinstalar los dotfiles:${NC}"
echo -e "${WHITE}    git clone git@github.com:herwingx/dotfiles.git ~/dotfiles${NC}"
echo -e "${WHITE}    cd ~/dotfiles && ./install.sh${NC}"
echo ""
