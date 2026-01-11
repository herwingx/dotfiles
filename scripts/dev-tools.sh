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
    echo -e "${GREEN}>>> Verificando autenticación GitHub CLI...${NC}"
    
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}   ✗ GitHub CLI no está instalado${NC}"
        return 1
    fi
    
    # Verificar si ya está autenticado ANTES de intentar descifrar
    if gh auth status &> /dev/null; then
        echo -e "${CYAN}   ✓ GitHub CLI ya autenticado (saltando login)${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}   ! No autenticado, se requieren credenciales...${NC}"
    
    # Solo descifrar si no tenemos el token en memoria
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
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    # Asegurar persistencia en .bashrc
    BASHRC="$HOME/.bashrc"
    if ! grep -q "export NVM_DIR" "$BASHRC"; then
        echo -e "${CYAN}   Configurando NVM en .bashrc...${NC}"
        cat >> "$BASHRC" <<'EOF'

# NVM Configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
EOF
    fi

    # Obtener versión LTS remota
    LTS_VERSION=$(nvm version-remote --lts)
    CURRENT_VERSION=$(node -v 2>/dev/null)
    
    if [ "$CURRENT_VERSION" = "$LTS_VERSION" ]; then
        echo -e "${YELLOW}   ! Node.js ya está en la última LTS ($current_version)${NC}"
    else
        echo -e "${CYAN}   Actualizando/Instalando Node.js LTS ($LTS_VERSION)...${NC}"
        nvm install --lts
        nvm use --lts
        nvm alias default 'lts/*'
        # Reinstalar paquetes globales si es necesario
        nvm reinstall-packages default 2>/dev/null || true
    fi
    
    echo -e "${CYAN}   ✓ NVM y Node.js configurados${NC}"
    echo -e "${CYAN}   Node: $(node --version 2>/dev/null || echo 'Pendiente de recarga')${NC}"
    echo -e "${CYAN}   npm: $(npm --version 2>/dev/null || echo 'Pendiente de recarga')${NC}"
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
        ["@google/gemini-cli"]="gemini"
    )
    
    for package in "${!NPM_PACKAGES[@]}"; do
        cmd="${NPM_PACKAGES[$package]}"
        
        # Verificar si el comando ya existe
        if command -v "$cmd" &> /dev/null; then
            # Obtener versión instalada
            INSTALLED_VERSION=$(npm list -g "$package" 2>/dev/null | grep "$package@" | sed 's/.*@//' | cut -d' ' -f1)
            
            # Obtener última versión disponible en npm
            LATEST_VERSION=$(npm view "$package" version 2>/dev/null)
            
            if [ -n "$INSTALLED_VERSION" ] && [ -n "$LATEST_VERSION" ]; then
                if [ "$INSTALLED_VERSION" = "$LATEST_VERSION" ]; then
                    echo -e "${YELLOW}   ! $cmd ya está en la última versión ($INSTALLED_VERSION)${NC}"
                    continue
                else
                    echo -e "${CYAN}   Actualizando $package: $INSTALLED_VERSION → $LATEST_VERSION${NC}"
                    $USE_SUDO npm install -g "$package@latest"
                    
                    if [ $? -ne 0 ]; then
                        echo -e "${RED}   ✗ Error actualizando $package${NC}"
                    else
                        echo -e "${CYAN}   ✓ $package actualizado${NC}"
                    fi
                    continue
                fi
            else
                echo -e "${YELLOW}   ! $cmd instalado pero no se pudo verificar versión${NC}"
                continue
            fi
        fi
        
        # Si no está instalado, instalarlo
        echo -e "${CYAN}   Instalando $package...${NC}"
        $USE_SUDO npm install -g "$package@latest"
        
        if [ $? -ne 0 ]; then
             echo -e "${RED}   ✗ Error instalando $package${NC}"
        else
             echo -e "${CYAN}   ✓ $package instalado${NC}"
        fi
    done
    
    # Refrescar hash para encontrar binarios recién instalados
    hash -r 2>/dev/null || true
    
    echo -e "${CYAN}   ✓ Paquetes npm verificados${NC}"
    
    # Buscar bw en el path de npm si no está en PATH
    BW_CMD=$(which bw 2>/dev/null || echo "$HOME/.nvm/versions/node/$(node -v 2>/dev/null)/bin/bw" 2>/dev/null)
    
    if [ -x "$BW_CMD" ] || command -v bw &> /dev/null; then
        bitwarden_login
    fi
}

# ─────────────────────────────────────────────────────────────
# Inicia sesión en Bitwarden CLI usando API key de secrets.
# Fallback a login tradicional si no hay secrets.
#
# Nota: bw login --apikey requiere que BW_CLIENTID y BW_CLIENTSECRET
# estén exportadas como variables de entorno ANTES de ejecutar el comando.
# ─────────────────────────────────────────────────────────────
bitwarden_login() {
    echo -e "${GREEN}>>> Verificando Bitwarden CLI...${NC}"
    
    if ! command -v bw &> /dev/null; then
        echo -e "${RED}   ✗ Bitwarden CLI no está instalado${NC}"
        return 1
    fi
    
    BW_STATUS=$(bw status 2>/dev/null | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    echo -e "${CYAN}   Estado actual: $BW_STATUS${NC}"
    
    # Si ya está autenticado (locked o unlocked), no hacer nada
    if [ "$BW_STATUS" = "unlocked" ]; then
        echo -e "${CYAN}   ✓ Bitwarden ya desbloqueado${NC}"
        bw sync &>/dev/null
        return 0
    fi
    
    if [ "$BW_STATUS" = "locked" ]; then
        echo -e "${CYAN}   ✓ Bitwarden ya autenticado (bóveda bloqueada)${NC}"
        echo -e "${YELLOW}   Tip: Usa 'bw unlock' cuando necesites acceder a la bóveda${NC}"
        return 0
    fi
    
    # Solo si está unauthenticated, hacer login con API keys
    if [ "$BW_STATUS" = "unauthenticated" ]; then
        echo -e "${YELLOW}   ! No autenticado, iniciando sesión...${NC}"
        
        # Cargar secrets si no están en memoria
        if [ -z "$BW_CLIENTID" ] || [ -z "$BW_CLIENTSECRET" ]; then
            decrypt_secrets
        fi
        
        # Verificar que las credenciales se cargaron correctamente
        if [ -n "$BW_CLIENTID" ] && [ -n "$BW_CLIENTSECRET" ]; then
            echo -e "${CYAN}   Usando API key (sin 2FA)...${NC}"
            
            # Debug: mostrar que las variables están cargadas (sin exponer valores)
            echo -e "${CYAN}   BW_CLIENTID: ${BW_CLIENTID:0:10}...${NC}"
            echo -e "${CYAN}   BW_CLIENTSECRET: ****${NC}"
            
            # Ejecutar login con variables de entorno explícitas
            BW_CLIENTID="$BW_CLIENTID" BW_CLIENTSECRET="$BW_CLIENTSECRET" bw login --apikey
            
            if [ $? -ne 0 ]; then
                echo -e "${RED}   ✗ Error en login${NC}"
                echo -e "${YELLOW}   Posibles causas:${NC}"
                echo -e "${YELLOW}   - API keys expiradas (regenerar en vault.bitwarden.com)${NC}"
                echo -e "${YELLOW}   - Client ID y Secret no coinciden${NC}"
                echo -e "${YELLOW}   - Problemas de conexión a Bitwarden${NC}"
                return 1
            fi
            echo -e "${CYAN}   ✓ Login exitoso (bóveda bloqueada)${NC}"
            echo -e "${YELLOW}   Tip: Usa 'bw unlock' cuando necesites acceder a la bóveda${NC}"
        else
            echo -e "${YELLOW}   ! API keys no disponibles en .env.age${NC}"
            echo -e "${YELLOW}   Agrega BW_CLIENTID y BW_CLIENTSECRET a tu archivo de secrets${NC}"
            echo -e "${YELLOW}   O usa 'bw login' manualmente${NC}"
        fi
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
