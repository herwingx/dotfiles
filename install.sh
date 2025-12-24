#!/bin/bash
# ==========================================
# SCRIPT DE INSTALACIÓN (herwingx)
# Con menú interactivo para seleccionar módulos
# ==========================================

# --- COLORES ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- DETECCIÓN DE PERMISOS (ROOT vs USER) ---
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${YELLOW}>>> Ejecutando como ROOT (Modo LXC detectado)${NC}"
    SUDO_CMD=""
else
    echo -e "${YELLOW}>>> Ejecutando como USUARIO (Modo VM detectado)${NC}"
    SUDO_CMD="sudo"
fi

DOTFILES_DIR=$(pwd)

# --- FUNCIONES DE INSTALACIÓN ---

update_system() {
    echo -e "${GREEN}>>> Actualizando el sistema...${NC}"
    
    if [ -f /etc/debian_version ]; then
        echo -e "${CYAN}   Detectado: Debian/Ubuntu (apt)${NC}"
        $SUDO_CMD apt-get update -y
        $SUDO_CMD apt-get upgrade -y
        $SUDO_CMD apt-get autoremove -y
    elif [ -f /etc/redhat-release ]; then
        echo -e "${CYAN}   Detectado: Fedora/RHEL (dnf)${NC}"
        $SUDO_CMD dnf upgrade --refresh -y
        $SUDO_CMD dnf autoremove -y
    elif [ -f /etc/arch-release ]; then
        echo -e "${CYAN}   Detectado: Arch Linux (pacman)${NC}"
        $SUDO_CMD pacman -Syu --noconfirm
    else
        echo -e "${RED}>>> Sistema no soportado para actualización automática${NC}"
        return
    fi
    
    echo -e "${CYAN}   ✓ Sistema actualizado${NC}"
}

install_packages() {
    echo -e "${GREEN}>>> Instalando paquetes del sistema...${NC}"
    PACKAGES=(
        "git" "curl" "wget" "htop" "btop" "vim" "unzip" "tree" "net-tools" "neofetch" "dnsutils"
    )
    
    if [ -f /etc/debian_version ]; then
        echo -e "${CYAN}   Detectado: Debian/Ubuntu (apt)${NC}"
        $SUDO_CMD apt-get update -y
        $SUDO_CMD apt-get install -y "${PACKAGES[@]}"
    elif [ -f /etc/redhat-release ]; then
        echo -e "${CYAN}   Detectado: Fedora/RHEL (dnf)${NC}"
        $SUDO_CMD dnf install -y "${PACKAGES[@]}"
    elif [ -f /etc/arch-release ]; then
        echo -e "${CYAN}   Detectado: Arch Linux (pacman)${NC}"
        $SUDO_CMD pacman -Syu --noconfirm "${PACKAGES[@]}"
    else
        echo -e "${RED}>>> Sistema no soportado para instalación automática de paquetes${NC}"
        echo -e "${YELLOW}   Instala manualmente: ${PACKAGES[*]}${NC}"
    fi
}

install_bash_aliases() {
    echo -e "${GREEN}>>> Vinculando Bash Aliases...${NC}"
    ALIAS_FILE="$HOME/.bash_aliases"
    [ -f "$ALIAS_FILE" ] && [ ! -L "$ALIAS_FILE" ] && mv "$ALIAS_FILE" "$ALIAS_FILE.backup"
    ln -sf "$DOTFILES_DIR/.bash_aliases" "$ALIAS_FILE"
    echo -e "${CYAN}   ✓ Aliases configurados${NC}"
}

install_gitconfig() {
    echo -e "${GREEN}>>> Configurando Git...${NC}"
    cp "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
    # Fuerza el uso de SSH aunque copies links HTTPS (Vital para forwarding)
    git config --global url."git@github.com:".insteadOf "https://github.com/"
    echo -e "${CYAN}   ✓ Git configurado${NC}"
}

install_ssh_keys() {
    echo -e "${GREEN}>>> Importando llaves públicas de herwingx...${NC}"
    mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    curl -s "https://github.com/herwingx.keys" >> "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys"
    echo -e "${CYAN}   ✓ Llaves SSH importadas${NC}"
}

install_antigravity_rules() {
    echo -e "${GREEN}>>> Configurando Antigravity - Reglas (GEMINI.md)...${NC}"
    GEMINI_DIR="$HOME/.gemini"
    
    if [ ! -d "$GEMINI_DIR" ]; then
        echo -e "${YELLOW}   ! Directorio ~/.gemini no existe. Creándolo...${NC}"
        mkdir -p "$GEMINI_DIR"
    fi
    
    if [ -f "$GEMINI_DIR/GEMINI.md" ]; then
        echo -e "${YELLOW}   ! GEMINI.md existente. Creando backup...${NC}"
        mv "$GEMINI_DIR/GEMINI.md" "$GEMINI_DIR/GEMINI.md.backup"
    fi
    
    cp "$DOTFILES_DIR/GEMINI.md" "$GEMINI_DIR/GEMINI.md"
    echo -e "${CYAN}   ✓ Reglas de Antigravity instaladas en $GEMINI_DIR${NC}"
}

install_antigravity_workflows() {
    echo -e "${GREEN}>>> Configurando Antigravity - Workflows...${NC}"
    WORKFLOWS_DIR="$HOME/.gemini/antigravity/global_workflows"
    
    if [ ! -d "$WORKFLOWS_DIR" ]; then
        echo -e "${YELLOW}   ! Directorio de workflows no existe. Creándolo...${NC}"
        mkdir -p "$WORKFLOWS_DIR"
    fi
    
    # Copiar todos los workflows
    if [ -d "$DOTFILES_DIR/global_workflows" ]; then
        cp -r "$DOTFILES_DIR/global_workflows/"* "$WORKFLOWS_DIR/"
        echo -e "${CYAN}   ✓ Workflows instalados en $WORKFLOWS_DIR${NC}"
        echo -e "${CYAN}   Workflows disponibles:${NC}"
        ls -1 "$WORKFLOWS_DIR" | while read workflow; do
            echo -e "${CYAN}     - /${workflow%.md}${NC}"
        done
    else
        echo -e "${RED}   ✗ No se encontró el directorio global_workflows en dotfiles${NC}"
    fi
}

install_antigravity_full() {
    install_antigravity_rules
    install_antigravity_workflows
}

# --- HERRAMIENTAS DE DESARROLLO ---

install_gh_cli() {
    echo -e "${GREEN}>>> Instalando GitHub CLI (gh)...${NC}"
    
    if command -v gh &> /dev/null; then
        echo -e "${YELLOW}   ! GitHub CLI ya está instalado: $(gh --version | head -1)${NC}"
        return
    fi
    
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | $SUDO_CMD dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        $SUDO_CMD chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | $SUDO_CMD tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        $SUDO_CMD apt-get update
        $SUDO_CMD apt-get install gh -y
    elif [ -f /etc/redhat-release ]; then
        # Fedora/RHEL
        $SUDO_CMD dnf install 'dnf-command(config-manager)' -y
        $SUDO_CMD dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
        $SUDO_CMD dnf install gh -y
    elif [ -f /etc/arch-release ]; then
        # Arch
        $SUDO_CMD pacman -S github-cli --noconfirm
    else
        echo -e "${RED}   ✗ Sistema no soportado. Instala gh manualmente: https://cli.github.com${NC}"
        return
    fi
    
    echo -e "${CYAN}   ✓ GitHub CLI instalado${NC}"
    echo -e "${YELLOW}   ! Ejecuta 'gh auth login' para autenticarte${NC}"
}

install_nvm_node() {
    echo -e "${GREEN}>>> Instalando NVM y Node.js...${NC}"
    
    # Verificar si NVM ya está instalado
    if [ -d "$HOME/.nvm" ]; then
        echo -e "${YELLOW}   ! NVM ya está instalado${NC}"
    else
        echo -e "${CYAN}   Descargando e instalando NVM...${NC}"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    fi
    
    # Cargar NVM para esta sesión
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Verificar si Node ya está instalado
    if command -v node &> /dev/null; then
        echo -e "${YELLOW}   ! Node.js ya está instalado: $(node --version)${NC}"
    else
        echo -e "${CYAN}   Instalando Node.js LTS...${NC}"
        nvm install --lts
        nvm use --lts
        nvm alias default 'lts/*'
    fi
    
    echo -e "${CYAN}   ✓ NVM y Node.js configurados${NC}"
    echo -e "${CYAN}   Node: $(node --version 2>/dev/null || echo 'reinicia terminal')${NC}"
    echo -e "${CYAN}   npm: $(npm --version 2>/dev/null || echo 'reinicia terminal')${NC}"
}

install_npm_global_packages() {
    echo -e "${GREEN}>>> Instalando paquetes npm globales...${NC}"
    
    # Cargar NVM si existe
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}   ✗ npm no está instalado. Ejecuta primero la opción de NVM + Node${NC}"
        return
    fi
    
    NPM_PACKAGES=(
        "@bitwarden/cli"
        "@anthropic-ai/claude-code"
    )
    
    for package in "${NPM_PACKAGES[@]}"; do
        echo -e "${CYAN}   Instalando $package...${NC}"
        npm install -g "$package"
    done
    
    echo -e "${CYAN}   ✓ Paquetes npm globales instalados${NC}"
    echo -e "${CYAN}   Disponibles: bw (Bitwarden), claude (Claude Code)${NC}"
}

install_docker() {
    echo -e "${GREEN}>>> Instalando Docker...${NC}"
    
    if command -v docker &> /dev/null; then
        echo -e "${YELLOW}   ! Docker ya está instalado: $(docker --version)${NC}"
        return
    fi
    
    if [ -f /etc/debian_version ]; then
        echo -e "${CYAN}   Detectado: Debian/Ubuntu${NC}"
        # Instalar dependencias
        $SUDO_CMD apt-get update
        $SUDO_CMD apt-get install -y ca-certificates curl gnupg
        
        # Agregar GPG key de Docker
        $SUDO_CMD install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO_CMD gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        $SUDO_CMD chmod a+r /etc/apt/keyrings/docker.gpg
        
        # Agregar repositorio
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | $SUDO_CMD tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Instalar Docker
        $SUDO_CMD apt-get update
        $SUDO_CMD apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
    elif [ -f /etc/redhat-release ]; then
        echo -e "${CYAN}   Detectado: Fedora/RHEL${NC}"
        $SUDO_CMD dnf -y install dnf-plugins-core
        $SUDO_CMD dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        $SUDO_CMD dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
    elif [ -f /etc/arch-release ]; then
        echo -e "${CYAN}   Detectado: Arch Linux${NC}"
        $SUDO_CMD pacman -S docker docker-compose --noconfirm
        
    else
        echo -e "${RED}   ✗ Sistema no soportado. Instala Docker manualmente: https://docs.docker.com/engine/install/${NC}"
        return
    fi
    
    # Iniciar y habilitar Docker
    $SUDO_CMD systemctl start docker
    $SUDO_CMD systemctl enable docker
    
    # Agregar usuario actual al grupo docker (evita usar sudo)
    if [ "$(id -u)" -ne 0 ]; then
        $SUDO_CMD usermod -aG docker "$USER"
        echo -e "${YELLOW}   ! Se agregó $USER al grupo docker. Cierra sesión y vuelve a entrar para aplicar.${NC}"
    fi
    
    echo -e "${CYAN}   ✓ Docker instalado${NC}"
    echo -e "${CYAN}   Docker: $(docker --version 2>/dev/null || echo 'reinicia sesión')${NC}"
}


install_dev_tools_all() {
    install_gh_cli
    install_nvm_node
    install_npm_global_packages
    install_docker
}

install_system_all() {
    update_system
    install_packages
    install_bash_aliases
    install_gitconfig
    install_ssh_keys
}

install_all() {
    update_system
    install_packages
    install_bash_aliases
    install_gitconfig
    install_ssh_keys
    install_dev_tools_all
    install_antigravity_full
}

# --- MENÚ INTERACTIVO ---
show_menu() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║            🚀 DOTFILES INSTALLER - herwingx 🚀                 ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    echo "║                                                                ║"
    echo "║  ${BOLD}INSTALACIÓN COMPLETA${NC}${CYAN}                                          ║"
    echo "║   1) Instalar TODO (sistema + dev tools + antigravity)         ║"
    echo "║   2) Solo Sistema (update + paquetes, aliases, git, ssh)       ║"
    echo "║   3) Solo Dev Tools (gh, nvm, node, npm packages, docker)      ║"
    echo "║                                                                ║"
    echo "║  ${BOLD}SISTEMA (individual)${NC}${CYAN}                                          ║"
    echo "║   4) Actualizar sistema (apt/dnf upgrade)                      ║"
    echo "║   5) Paquetes del sistema (git, curl, vim, htop, etc.)         ║"
    echo "║   6) Bash Aliases                                              ║"
    echo "║   7) Git Config                                                ║"
    echo "║   8) SSH Keys                                                  ║"
    echo "║                                                                ║"
    echo "║  ${BOLD}DEV TOOLS (individual)${NC}${CYAN}                                        ║"
    echo "║   9) GitHub CLI (gh)                                           ║"
    echo "║  10) NVM + Node.js LTS                                         ║"
    echo "║  11) npm packages (bitwarden-cli, claude-code)                 ║"
    echo "║  12) Docker + Docker Compose                                   ║"
    echo "║                                                                ║"
    echo "║  ${BOLD}ANTIGRAVITY (Gemini AI)${NC}${CYAN}                                       ║"
    echo "║  13) Antigravity Completo (reglas + workflows)                 ║"
    echo "║  14) Solo Reglas (GEMINI.md)                                   ║"
    echo "║  15) Solo Workflows (/commit, /publicar, etc.)                 ║"
    echo "║                                                                ║"
    echo "║   0) Salir                                                     ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    read -p "Selecciona una opción [0-15]: " choice
    
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
            update_system
            ;;
        5)
            install_packages
            ;;
        6)
            install_bash_aliases
            ;;
        7)
            install_gitconfig
            ;;
        8)
            install_ssh_keys
            ;;
        9)
            install_gh_cli
            ;;
        10)
            install_nvm_node
            ;;
        11)
            install_npm_global_packages
            ;;
        12)
            install_docker
            ;;
        13)
            install_antigravity_full
            ;;
        14)
            install_antigravity_rules
            ;;
        15)
            install_antigravity_workflows
            ;;
        0)
            echo -e "${GREEN}>>> ¡Hasta luego!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}>>> Opción inválida${NC}"
            sleep 1
            show_menu
            ;;
    esac
}

# --- MAIN ---
show_menu

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          ✅ ¡INSTALACIÓN COMPLETADA!                     ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Mostrar neofetch si está instalado
if command -v neofetch &> /dev/null; then
    neofetch
fi