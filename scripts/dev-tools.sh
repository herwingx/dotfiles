#!/bin/bash
# ==========================================
# DEV-TOOLS - Herramientas de desarrollo
# ==========================================
# Funciones para instalar herramientas de desarrollo:
# GitHub CLI, NVM/Node.js, paquetes npm globales y Docker.
# Incluye verificación de instalaciones existentes.
# ==========================================

# ─────────────────────────────────────────────────────────────
# Instala GitHub CLI (gh) y ejecuta autenticación automática.
# Soporta Debian/Ubuntu, Fedora/RHEL y Arch Linux.
# ─────────────────────────────────────────────────────────────
install_gh_cli() {
    echo -e "${GREEN}>>> Instalando GitHub CLI (gh)...${NC}"
    
    if command -v gh &> /dev/null; then
        echo -e "${YELLOW}   ! GitHub CLI ya está instalado: $(gh --version | head -1)${NC}"
    else
        if [ -f /etc/debian_version ]; then
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | $SUDO_CMD dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            $SUDO_CMD chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | $SUDO_CMD tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            $SUDO_CMD apt-get update
            $SUDO_CMD apt-get install gh -y
        elif [ -f /etc/redhat-release ]; then
            $SUDO_CMD dnf install 'dnf-command(config-manager)' -y
            $SUDO_CMD dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
            $SUDO_CMD dnf install gh -y
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S github-cli --noconfirm
        else
            echo -e "${RED}   ✗ Sistema no soportado. Instala gh manualmente.${NC}"
            return
        fi
        echo -e "${CYAN}   ✓ GitHub CLI instalado${NC}"
    fi
    
    gh_auth_login
}

# ─────────────────────────────────────────────────────────────
# Autentica GitHub CLI usando token de secrets encriptados.
# Fallback a método interactivo si no hay token disponible.
# ─────────────────────────────────────────────────────────────
gh_auth_login() {
    echo -e "${GREEN}>>> Autenticando GitHub CLI...${NC}"
    
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}   ✗ GitHub CLI no está instalado${NC}"
        return 1
    fi
    
    if gh auth status &> /dev/null; then
        echo -e "${YELLOW}   ! Ya estás autenticado en GitHub${NC}"
        return 0
    fi
    
    if [ -z "$GH_TOKEN" ]; then
        decrypt_secrets
    fi
    
    if [ -n "$GH_TOKEN" ]; then
        echo -e "${CYAN}   Usando token de secrets encriptados...${NC}"
        echo "$GH_TOKEN" | gh auth login --with-token
        if [ $? -eq 0 ]; then
            echo -e "${CYAN}   ✓ Autenticación exitosa${NC}"
            return 0
        fi
    fi
    
    echo -e "${YELLOW}   ! Secrets no disponibles, usando método interactivo${NC}"
    gh auth login
}

# ─────────────────────────────────────────────────────────────
# Instala NVM (Node Version Manager) y Node.js LTS.
# Si ya están instalados, muestra las versiones actuales.
# ─────────────────────────────────────────────────────────────
install_nvm_node() {
    echo -e "${GREEN}>>> Instalando NVM y Node.js...${NC}"
    
    if [ -d "$HOME/.nvm" ]; then
        echo -e "${YELLOW}   ! NVM ya está instalado${NC}"
    else
        echo -e "${CYAN}   Descargando e instalando NVM...${NC}"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    fi
    
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
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

# ─────────────────────────────────────────────────────────────
# Instala paquetes npm globales verificando si ya existen.
# Paquetes: @bitwarden/cli (bw), @anthropic-ai/claude-code (claude)
# ─────────────────────────────────────────────────────────────
install_npm_global_packages() {
    echo -e "${GREEN}>>> Instalando paquetes npm globales...${NC}"
    
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    NPM_PATH=$(which npm 2>/dev/null)
    
    if [ -z "$NPM_PATH" ]; then
        echo -e "${YELLOW}   ! npm no está instalado${NC}"
        read -p "   ¿Deseas instalar NVM + Node ahora? (s/n): " install_nvm
        if [[ "$install_nvm" =~ ^[Ss]$ ]]; then
            install_nvm_node
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            NPM_PATH=$(which npm 2>/dev/null)
        else
            echo -e "${RED}   ✗ Necesitas npm para continuar.${NC}"
            return 1
        fi
    fi
    
    # Sin sudo si usa NVM
    USE_SUDO=""
    if [[ "$NPM_PATH" == *".nvm"* ]]; then
        echo -e "${CYAN}   Usando npm de NVM (sin sudo)${NC}"
    else
        echo -e "${CYAN}   Usando npm del sistema (con sudo)${NC}"
        USE_SUDO="$SUDO_CMD"
    fi
    
    # Paquetes con sus comandos para verificar
    declare -A NPM_PACKAGES=(
        ["@bitwarden/cli"]="bw"
        ["@anthropic-ai/claude-code"]="claude"
    )
    
    for package in "${!NPM_PACKAGES[@]}"; do
        cmd="${NPM_PACKAGES[$package]}"
        
        if command -v "$cmd" &> /dev/null; then
            echo -e "${YELLOW}   ! $package ya está instalado ($cmd)${NC}"
        else
            echo -e "${CYAN}   Instalando $package...${NC}"
            $USE_SUDO npm install -g "$package"
            if [ $? -ne 0 ]; then
                echo -e "${RED}   ✗ Error instalando $package${NC}"
            else
                echo -e "${CYAN}   ✓ $package instalado${NC}"
            fi
        fi
    done
    
    echo -e "${CYAN}   ✓ Paquetes npm verificados${NC}"
    
    if command -v bw &> /dev/null; then
        bitwarden_login
    fi
}

# ─────────────────────────────────────────────────────────────
# Inicia sesión en Bitwarden CLI usando API key de secrets.
# Fallback a login tradicional si no hay secrets.
# ─────────────────────────────────────────────────────────────
bitwarden_login() {
    echo -e "${GREEN}>>> Iniciando sesión en Bitwarden...${NC}"
    
    if ! command -v bw &> /dev/null; then
        echo -e "${RED}   ✗ Bitwarden CLI no está instalado${NC}"
        return 1
    fi
    
    BW_STATUS=$(bw status 2>/dev/null | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    
    if [ "$BW_STATUS" = "unauthenticated" ]; then
        if [ -z "$BW_CLIENTID" ] || [ -z "$BW_CLIENTSECRET" ]; then
            decrypt_secrets
        fi
        
        if [ -n "$BW_CLIENTID" ] && [ -n "$BW_CLIENTSECRET" ]; then
            echo -e "${CYAN}   Usando API key (sin 2FA)...${NC}"
            bw login --apikey
            [ $? -eq 0 ] && echo -e "${CYAN}   ✓ Login exitoso${NC}" || return 1
        else
            echo -e "${YELLOW}   ! Usando login tradicional${NC}"
            bw login "herwingmacias@gmail.com"
        fi
    elif [ "$BW_STATUS" = "locked" ]; then
        echo -e "${YELLOW}   ! Sesión bloqueada${NC}"
    else
        echo -e "${YELLOW}   ! Ya estás logueado en Bitwarden${NC}"
    fi
    
    echo -e "${CYAN}   Desbloqueando bóveda...${NC}"
    BW_SESSION=$(bw unlock --raw)
    
    if [ -n "$BW_SESSION" ]; then
        export BW_SESSION
        echo -e "${CYAN}   ✓ Bitwarden desbloqueado${NC}"
        bw sync &>/dev/null
        echo -e "${CYAN}   ✓ Bóveda sincronizada${NC}"
    else
        echo -e "${RED}   ✗ Error desbloqueando${NC}"
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────
# Instala Docker y Docker Compose.
# Agrega el usuario actual al grupo docker.
# ─────────────────────────────────────────────────────────────
install_docker() {
    echo -e "${GREEN}>>> Instalando Docker...${NC}"
    
    if command -v docker &> /dev/null; then
        echo -e "${YELLOW}   ! Docker ya está instalado: $(docker --version)${NC}"
        return
    fi
    
    if [ -f /etc/debian_version ]; then
        echo -e "${CYAN}   Detectado: Debian/Ubuntu${NC}"
        $SUDO_CMD apt-get update
        $SUDO_CMD apt-get install -y ca-certificates curl gnupg
        
        $SUDO_CMD install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO_CMD gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        $SUDO_CMD chmod a+r /etc/apt/keyrings/docker.gpg
        
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | $SUDO_CMD tee /etc/apt/sources.list.d/docker.list > /dev/null
        
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
        echo -e "${RED}   ✗ Sistema no soportado.${NC}"
        return
    fi
    
    $SUDO_CMD systemctl start docker
    $SUDO_CMD systemctl enable docker
    
    if [ "$(id -u)" -ne 0 ]; then
        $SUDO_CMD usermod -aG docker "$USER"
        echo -e "${YELLOW}   ! Cierra sesión y vuelve a entrar para usar docker sin sudo.${NC}"
    fi
    
    echo -e "${CYAN}   ✓ Docker instalado${NC}"
}

# ─────────────────────────────────────────────────────────────
# Instalación agrupada de todas las herramientas de desarrollo.
# ─────────────────────────────────────────────────────────────
install_dev_tools_all() {
    install_gh_cli
    install_nvm_node
    install_npm_global_packages
    install_docker
}
