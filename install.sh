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

copy_ssh_from_windows() {
    echo -e "${GREEN}>>> Copiando llaves SSH desde Windows a WSL...${NC}"
    
    # Verificar si estamos en WSL
    if [ ! -d "/mnt/c" ]; then
        echo -e "${RED}   ✗ No se detectó WSL. Esta opción solo funciona en Windows Subsystem for Linux.${NC}"
        return 1
    fi
    
    # Detectar usuario de Windows automáticamente
    # Opción 1: Usar variable de entorno de Windows
    if [ -n "$WSLENV" ] || [ -f "/proc/sys/fs/binfmt_misc/WSLInterop" ]; then
        # Obtener el usuario de Windows desde el path del home de Windows
        WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
        
        # Si falla, intentar detectar desde /mnt/c/Users
        if [ -z "$WIN_USER" ] || [ "$WIN_USER" = "%USERNAME%" ]; then
            # Buscar el directorio de usuario más reciente en /mnt/c/Users (excluyendo los del sistema)
            WIN_USER=$(ls -td /mnt/c/Users/*/ 2>/dev/null | grep -v -E "(Public|Default|All Users)" | head -1 | xargs basename)
        fi
    fi
    
    if [ -z "$WIN_USER" ]; then
        echo -e "${YELLOW}   ! No se pudo detectar el usuario de Windows automáticamente.${NC}"
        read -p "   Ingresa tu nombre de usuario de Windows: " WIN_USER
    fi
    
    WIN_SSH_DIR="/mnt/c/Users/$WIN_USER/.ssh"
    
    if [ ! -d "$WIN_SSH_DIR" ]; then
        echo -e "${RED}   ✗ No se encontró el directorio SSH en: $WIN_SSH_DIR${NC}"
        echo -e "${YELLOW}   Verifica que existan llaves SSH en Windows.${NC}"
        return 1
    fi
    
    echo -e "${CYAN}   Usuario de Windows detectado: $WIN_USER${NC}"
    echo -e "${CYAN}   Copiando desde: $WIN_SSH_DIR${NC}"
    
    # Crear directorio .ssh en Linux si no existe
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    
    # Copiar llaves privadas y públicas
    KEYS_COPIED=0
    for key_type in id_rsa id_ed25519 id_ecdsa; do
        if [ -f "$WIN_SSH_DIR/$key_type" ]; then
            cp "$WIN_SSH_DIR/$key_type" "$HOME/.ssh/"
            chmod 600 "$HOME/.ssh/$key_type"
            echo -e "${CYAN}   ✓ Copiada: $key_type${NC}"
            KEYS_COPIED=$((KEYS_COPIED + 1))
        fi
        if [ -f "$WIN_SSH_DIR/$key_type.pub" ]; then
            cp "$WIN_SSH_DIR/$key_type.pub" "$HOME/.ssh/"
            chmod 644 "$HOME/.ssh/$key_type.pub"
        fi
    done
    
    # Copiar config si existe
    if [ -f "$WIN_SSH_DIR/config" ]; then
        cp "$WIN_SSH_DIR/config" "$HOME/.ssh/"
        chmod 600 "$HOME/.ssh/config"
        echo -e "${CYAN}   ✓ Copiado: config${NC}"
    fi
    
    # Copiar known_hosts si existe
    if [ -f "$WIN_SSH_DIR/known_hosts" ]; then
        cp "$WIN_SSH_DIR/known_hosts" "$HOME/.ssh/"
        chmod 600 "$HOME/.ssh/known_hosts"
        echo -e "${CYAN}   ✓ Copiado: known_hosts${NC}"
    fi
    
    if [ $KEYS_COPIED -eq 0 ]; then
        echo -e "${YELLOW}   ! No se encontraron llaves SSH para copiar.${NC}"
        return 1
    fi
    
    echo -e "${CYAN}   ✓ $KEYS_COPIED llave(s) SSH copiada(s) exitosamente${NC}"
    
    # Probar conexión a GitHub
    echo -e "${CYAN}   Probando conexión a GitHub...${NC}"
    ssh -T git@github.com 2>&1 | head -2
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
    else
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
    fi
    
    # Preguntar si desea autenticarse
    echo ""
    read -p "   ¿Deseas autenticarte con GitHub ahora? (s/n): " auth_choice
    if [[ "$auth_choice" =~ ^[Ss]$ ]]; then
        gh_auth_login
    fi
}

gh_auth_login() {
    echo -e "${GREEN}>>> Autenticando GitHub CLI...${NC}"
    
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}   ✗ GitHub CLI no está instalado${NC}"
        return 1
    fi
    
    # Verificar si ya está autenticado
    if gh auth status &> /dev/null; then
        echo -e "${YELLOW}   ! Ya estás autenticado en GitHub${NC}"
        gh auth status
        return
    fi
    
    # Intentar obtener token de Bitwarden primero
    if command -v bw &> /dev/null; then
        echo -e "${CYAN}   Intentando obtener token desde Bitwarden...${NC}"
        
        # Verificar si Bitwarden está desbloqueado
        BW_STATUS=$(bw status 2>/dev/null | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        
        if [ "$BW_STATUS" = "unlocked" ]; then
            # Intentar obtener el token
            GH_TOKEN=$(bw get notes "Github Personal Access Token" 2>/dev/null)
            
            if [ -n "$GH_TOKEN" ]; then
                echo -e "${CYAN}   Token encontrado en Bitwarden${NC}"
                echo "$GH_TOKEN" | gh auth login --with-token
                if [ $? -eq 0 ]; then
                    echo -e "${CYAN}   ✓ Autenticación exitosa (desde Bitwarden)${NC}"
                    return 0
                else
                    echo -e "${YELLOW}   ! Token de Bitwarden falló, usando método alternativo${NC}"
                fi
            else
                echo -e "${YELLOW}   ! No se encontró 'Github Personal Access Token' en Bitwarden${NC}"
            fi
        elif [ "$BW_STATUS" = "locked" ]; then
            echo -e "${YELLOW}   ! Bitwarden está bloqueado${NC}"
            read -p "   ¿Deseas desbloquearlo para obtener el token? (s/n): " unlock_bw
            if [[ "$unlock_bw" =~ ^[Ss]$ ]]; then
                BW_SESSION=$(bw unlock --raw 2>/dev/null)
                if [ -n "$BW_SESSION" ]; then
                    export BW_SESSION
                    GH_TOKEN=$(bw get notes "Github Personal Access Token" 2>/dev/null)
                    if [ -n "$GH_TOKEN" ]; then
                        echo "$GH_TOKEN" | gh auth login --with-token
                        if [ $? -eq 0 ]; then
                            echo -e "${CYAN}   ✓ Autenticación exitosa (desde Bitwarden)${NC}"
                            return 0
                        fi
                    fi
                fi
            fi
        else
            echo -e "${YELLOW}   ! Bitwarden no está logueado${NC}"
        fi
    fi
    
    # Fallback: métodos manuales
    echo -e "${CYAN}   Métodos alternativos:${NC}"
    echo -e "   1) Interactivo (abre navegador)"
    echo -e "   2) Pegar token manualmente"
    echo -e "   3) Cancelar"
    read -p "   Selecciona [1-3]: " auth_method
    
    case $auth_method in
        1)
            gh auth login
            ;;
        2)
            echo -e "${YELLOW}   Genera un token en: https://github.com/settings/tokens${NC}"
            echo -e "${YELLOW}   Permisos recomendados: repo, read:org, workflow${NC}"
            read -sp "   Pega tu token (no se mostrará): " gh_token
            echo ""
            if [ -n "$gh_token" ]; then
                echo "$gh_token" | gh auth login --with-token
                if [ $? -eq 0 ]; then
                    echo -e "${CYAN}   ✓ Autenticación exitosa${NC}"
                else
                    echo -e "${RED}   ✗ Error en la autenticación${NC}"
                fi
            fi
            ;;
        *)
            echo -e "${YELLOW}   Autenticación cancelada${NC}"
            ;;
    esac
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
    
    # Intentar cargar NVM si existe
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Detectar npm disponible
    NPM_PATH=$(which npm 2>/dev/null)
    
    if [ -z "$NPM_PATH" ]; then
        # No hay npm instalado, ofrecer instalar NVM
        echo -e "${YELLOW}   ! npm no está instalado${NC}"
        read -p "   ¿Deseas instalar NVM + Node ahora? (s/n): " install_nvm
        if [[ "$install_nvm" =~ ^[Ss]$ ]]; then
            install_nvm_node
            # Recargar NVM
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            NPM_PATH=$(which npm 2>/dev/null)
        else
            echo -e "${RED}   ✗ Instalación cancelada. Necesitas npm para continuar.${NC}"
            return 1
        fi
    fi
    
    # Determinar si usar sudo o no
    USE_SUDO=""
    if [[ "$NPM_PATH" == *".nvm"* ]]; then
        echo -e "${CYAN}   Usando npm de NVM: $NPM_PATH (sin sudo)${NC}"
    else
        echo -e "${CYAN}   Usando npm del sistema: $NPM_PATH (con sudo)${NC}"
        USE_SUDO="$SUDO_CMD"
    fi
    
    NPM_PACKAGES=(
        "@bitwarden/cli"
        "@anthropic-ai/claude-code"
    )
    
    for package in "${NPM_PACKAGES[@]}"; do
        echo -e "${CYAN}   Instalando $package...${NC}"
        $USE_SUDO npm install -g "$package"
        if [ $? -ne 0 ]; then
            echo -e "${RED}   ✗ Error instalando $package${NC}"
        else
            echo -e "${CYAN}   ✓ $package instalado${NC}"
        fi
    done
    
    echo -e "${CYAN}   ✓ Paquetes npm globales instalados${NC}"
    echo -e "${CYAN}   Disponibles: bw (Bitwarden), claude (Claude Code)${NC}"
    
    # Ofrecer login a Bitwarden
    if command -v bw &> /dev/null; then
        echo ""
        read -p "   ¿Deseas iniciar sesión en Bitwarden ahora? (s/n): " bw_login
        if [[ "$bw_login" =~ ^[Ss]$ ]]; then
            bitwarden_login
        fi
    fi
}

bitwarden_login() {
    echo -e "${GREEN}>>> Iniciando sesión en Bitwarden...${NC}"
    
    if ! command -v bw &> /dev/null; then
        echo -e "${RED}   ✗ Bitwarden CLI no está instalado${NC}"
        return 1
    fi
    
    # Verificar si ya está logueado
    BW_STATUS=$(bw status 2>/dev/null | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    
    if [ "$BW_STATUS" = "unauthenticated" ]; then
        echo -e "${CYAN}   Iniciando sesión...${NC}"
        bw login
    elif [ "$BW_STATUS" = "locked" ]; then
        echo -e "${YELLOW}   ! Sesión existente pero bloqueada${NC}"
    else
        echo -e "${YELLOW}   ! Ya estás logueado en Bitwarden${NC}"
    fi
    
    # Desbloquear bóveda
    echo -e "${CYAN}   Desbloqueando bóveda...${NC}"
    echo -e "${YELLOW}   (Ingresa tu Master Password)${NC}"
    BW_SESSION=$(bw unlock --raw 2>/dev/null)
    
    if [ -n "$BW_SESSION" ]; then
        export BW_SESSION
        echo -e "${CYAN}   ✓ Bitwarden desbloqueado${NC}"
        echo -e "${YELLOW}   ! Sesión válida solo para esta terminal${NC}"
        
        # Sincronizar
        bw sync &>/dev/null
        echo -e "${CYAN}   ✓ Bóveda sincronizada${NC}"
    else
        echo -e "${RED}   ✗ Error desbloqueando Bitwarden${NC}"
        return 1
    fi
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
    echo -e "╔════════════════════════════════════════════════════════════════╗"
    echo -e "║            🚀 DOTFILES INSTALLER - herwingx 🚀                 ║"
    echo -e "╠════════════════════════════════════════════════════════════════╣"
    echo -e "║                                                                ║"
    echo -e "║  ${BOLD}INSTALACIÓN COMPLETA${NC}${CYAN}                                          ║"
    echo -e "║   1) Instalar TODO (sistema + dev tools + antigravity)         ║"
    echo -e "║   2) Solo Sistema (update + paquetes, aliases, git, ssh)       ║"
    echo -e "║   3) Solo Dev Tools (gh, nvm, node, npm packages, docker)      ║"
    echo -e "║   4) Solo Antigravity (reglas + workflows)                     ║"
    echo -e "║                                                                ║"
    echo -e "║  ${BOLD}SISTEMA (individual)${NC}${CYAN}                                          ║"
    echo -e "║   5) Actualizar sistema (apt/dnf upgrade)                      ║"
    echo -e "║   6) Paquetes del sistema (git, curl, vim, htop, etc.)         ║"
    echo -e "║   7) Bash Aliases                                              ║"
    echo -e "║   8) Git Config                                                ║"
    echo -e "║   9) SSH Keys (importar desde GitHub)                          ║"
    echo -e "║  10) Copiar SSH desde Windows (solo WSL)                       ║"
    echo -e "║                                                                ║"
    echo -e "║  ${BOLD}DEV TOOLS (individual)${NC}${CYAN}                                        ║"
    echo -e "║  11) GitHub CLI (gh + auth)                                    ║"
    echo -e "║  12) NVM + Node.js LTS                                         ║"
    echo -e "║  13) npm packages (bitwarden-cli, claude-code)                 ║"
    echo -e "║  14) Docker + Docker Compose                                   ║"
    echo -e "║                                                                ║"
    echo -e "║  ${BOLD}ANTIGRAVITY (individual)${NC}${CYAN}                                      ║"
    echo -e "║  15) Solo Reglas (GEMINI.md)                                   ║"
    echo -e "║  16) Solo Workflows (/commit, /publicar, etc.)                 ║"
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
            install_bash_aliases
            ;;
        8)
            install_gitconfig
            ;;
        9)
            install_ssh_keys
            ;;
        10)
            copy_ssh_from_windows
            ;;
        11)
            install_gh_cli
            ;;
        12)
            install_nvm_node
            ;;
        13)
            install_npm_global_packages
            ;;
        14)
            install_docker
            ;;
        15)
            install_antigravity_rules
            ;;
        16)
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