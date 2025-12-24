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

# --- SECRETS ENCRIPTADOS ---
# El archivo .env.age contiene las credenciales encriptadas con age
# Solo se descifran cuando se necesitan (login de Bitwarden/GitHub)

decrypt_secrets() {
    if [ -f "$DOTFILES_DIR/.env.age" ]; then
        if ! command -v age &> /dev/null; then
            echo -e "${YELLOW}   age no instalado, instalando...${NC}"
            if [ -f /etc/debian_version ]; then
                $SUDO_CMD apt-get install -y age
            elif [ -f /etc/redhat-release ]; then
                $SUDO_CMD dnf install -y age
            elif [ -f /etc/arch-release ]; then
                $SUDO_CMD pacman -S age --noconfirm
            fi
        fi
        
        if [ -z "$SECRETS_LOADED" ]; then
            echo -e "${CYAN}   Descifrando secrets...${NC}"
            DECRYPTED=$(age --decrypt "$DOTFILES_DIR/.env.age" 2>/dev/null)
            if [ $? -eq 0 ]; then
                export BW_CLIENTID=$(echo "$DECRYPTED" | grep "BW_CLIENTID" | cut -d'=' -f2)
                export BW_CLIENTSECRET=$(echo "$DECRYPTED" | grep "BW_CLIENTSECRET" | cut -d'=' -f2)
                export GH_TOKEN=$(echo "$DECRYPTED" | grep "GH_TOKEN" | cut -d'=' -f2)
                export SECRETS_LOADED=1
                echo -e "${CYAN}   ✓ Secrets cargados${NC}"
                return 0
            else
                echo -e "${RED}   ✗ Error descifrando (passphrase incorrecta?)${NC}"
                return 1
            fi
        fi
    else
        echo -e "${YELLOW}   ! Archivo .env.age no encontrado${NC}"
        return 1
    fi
}

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
    echo -e "${GREEN}>>> Instalando paquetes del sistema y herramientas de terminal...${NC}"
    
    # Paquetes base disponibles en todos los repos
    PACKAGES=(
        "git" "curl" "wget" "htop" "btop" "vim" "unzip" "tree" 
        "net-tools" "neofetch" "tmux" "fzf" "ranger" "mc"
    )
    
    if [ -f /etc/debian_version ]; then
        echo -e "${CYAN}   Detectado: Debian/Ubuntu (apt)${NC}"
        $SUDO_CMD apt-get update -y
        $SUDO_CMD apt-get install -y "${PACKAGES[@]}" dnsutils w3m-img
    elif [ -f /etc/redhat-release ]; then
        echo -e "${CYAN}   Detectado: Fedora/RHEL (dnf)${NC}"
        $SUDO_CMD dnf install -y "${PACKAGES[@]}" bind-utils w3m-img
    elif [ -f /etc/arch-release ]; then
        echo -e "${CYAN}   Detectado: Arch Linux (pacman)${NC}"
        $SUDO_CMD pacman -Syu --noconfirm "${PACKAGES[@]}" bind w3m
    else
        echo -e "${RED}>>> Sistema no soportado para instalación automática de paquetes${NC}"
        echo -e "${YELLOW}   Instala manualmente: ${PACKAGES[*]}${NC}"
        return
    fi
    
    # Configurar ranger
    if command -v ranger &> /dev/null; then
        if [ ! -d "$HOME/.config/ranger" ]; then
            echo -e "${CYAN}   Configurando ranger...${NC}"
            ranger --copy-config=all
        fi
    fi
    
    echo -e "${CYAN}   ✓ Paquetes base instalados${NC}"
    
    # Instalar herramientas avanzadas (lsd, lazydocker, ctop, gping)
    install_terminal_tools
    
    # Instalar aliases (incluye lsd como ls)
    install_bash_aliases
    
    echo -e "${CYAN}   ✓ Sistema completo configurado${NC}"
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
    
    # Autenticar automáticamente
    gh_auth_login
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
        return 0
    fi
    
    # Método 1: Usar token de secrets encriptados
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
    
    # Método 2: Fallback interactivo
    echo -e "${YELLOW}   ! Secrets no disponibles, usando método interactivo${NC}"
    gh auth login
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
    
    # Login automático a Bitwarden
    if command -v bw &> /dev/null; then
        bitwarden_login
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
        # Intentar usar API key de secrets encriptados
        if [ -z "$BW_CLIENTID" ] || [ -z "$BW_CLIENTSECRET" ]; then
            decrypt_secrets
        fi
        
        if [ -n "$BW_CLIENTID" ] && [ -n "$BW_CLIENTSECRET" ]; then
            echo -e "${CYAN}   Usando API key de secrets encriptados (sin 2FA)...${NC}"
            bw login --apikey
            if [ $? -eq 0 ]; then
                echo -e "${CYAN}   ✓ Login exitoso${NC}"
            else
                echo -e "${RED}   ✗ Error en login con API key${NC}"
                return 1
            fi
        else
            # Fallback a login tradicional
            echo -e "${YELLOW}   ! Secrets no disponibles, usando login tradicional${NC}"
            bw login "herwingmacias@gmail.com"
        fi
    elif [ "$BW_STATUS" = "locked" ]; then
        echo -e "${YELLOW}   ! Sesión existente pero bloqueada${NC}"
    else
        echo -e "${YELLOW}   ! Ya estás logueado en Bitwarden${NC}"
    fi
    
    # Desbloquear bóveda (siempre requiere master password)
    echo -e "${CYAN}   Desbloqueando bóveda...${NC}"
    BW_SESSION=$(bw unlock --raw)
    
    if [ -n "$BW_SESSION" ]; then
        export BW_SESSION
        echo -e "${CYAN}   ✓ Bitwarden desbloqueado${NC}"
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

install_terminal_tools() {
    echo -e "${GREEN}>>> Instalando herramientas avanzadas de terminal...${NC}"
    
    # LSD - LSDeluxe (ls moderno con iconos)
    if ! command -v lsd &> /dev/null; then
        echo -e "${CYAN}   Instalando lsd (ls moderno)...${NC}"
        if [ -f /etc/debian_version ]; then
            # Descargar .deb desde GitHub releases
            LSD_VERSION="1.1.5"
            wget -q "https://github.com/lsd-rs/lsd/releases/download/v${LSD_VERSION}/lsd_${LSD_VERSION}_amd64.deb" -O /tmp/lsd.deb
            $SUDO_CMD dpkg -i /tmp/lsd.deb
            rm /tmp/lsd.deb
        elif [ -f /etc/redhat-release ]; then
            $SUDO_CMD dnf install lsd -y 2>/dev/null || {
                # Si no está en repos, instalar con cargo
                if command -v cargo &> /dev/null; then
                    cargo install lsd
                else
                    echo -e "${YELLOW}   ! lsd no disponible. Instala cargo o descárgalo manualmente.${NC}"
                fi
            }
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S lsd --noconfirm
        fi
        echo -e "${CYAN}   ✓ lsd instalado${NC}"
    else
        echo -e "${YELLOW}   ! lsd ya está instalado${NC}"
    fi
    
    # Lazydocker - TUI para Docker
    if ! command -v lazydocker &> /dev/null; then
        echo -e "${CYAN}   Instalando lazydocker...${NC}"
        curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
        echo -e "${CYAN}   ✓ lazydocker instalado${NC}"
    else
        echo -e "${YELLOW}   ! lazydocker ya está instalado${NC}"
    fi
    
    # Ctop - Top para containers
    if ! command -v ctop &> /dev/null; then
        echo -e "${CYAN}   Instalando ctop...${NC}"
        if [ -f /etc/debian_version ]; then
            $SUDO_CMD wget https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64 -O /usr/local/bin/ctop
            $SUDO_CMD chmod +x /usr/local/bin/ctop
        elif [ -f /etc/redhat-release ]; then
            $SUDO_CMD wget https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64 -O /usr/local/bin/ctop
            $SUDO_CMD chmod +x /usr/local/bin/ctop
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S ctop --noconfirm
        fi
        echo -e "${CYAN}   ✓ ctop instalado${NC}"
    else
        echo -e "${YELLOW}   ! ctop ya está instalado${NC}"
    fi
    
    # Gping - Ping visual
    if ! command -v gping &> /dev/null; then
        echo -e "${CYAN}   Instalando gping...${NC}"
        if [ -f /etc/debian_version ]; then
            # Usar cargo si está disponible, si no descargar binario
            if command -v cargo &> /dev/null; then
                cargo install gping
            else
                echo -e "${YELLOW}   ! gping requiere cargo. Instala rust primero o instálalo manualmente.${NC}"
            fi
        elif [ -f /etc/redhat-release ]; then
            $SUDO_CMD dnf copr enable atim/gping -y 2>/dev/null || true
            $SUDO_CMD dnf install gping -y 2>/dev/null || echo -e "${YELLOW}   ! gping no disponible en repos${NC}"
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S gping --noconfirm
        fi
    else
        echo -e "${YELLOW}   ! gping ya está instalado${NC}"
    fi
    
    echo -e "${CYAN}   ✓ Herramientas de terminal instaladas${NC}"
    echo -e "${CYAN}   Disponibles: lsd, lazydocker, ctop, gping${NC}"
}

install_dev_tools_all() {
    install_gh_cli
    install_nvm_node
    install_npm_global_packages
    install_docker
}

install_system_all() {
    update_system
    install_packages  # Ya incluye terminal_tools y bash_aliases
    install_gitconfig
    install_ssh_keys
}

install_all() {
    update_system
    install_packages  # Ya incluye terminal_tools y bash_aliases
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
    echo -e "║   0) Salir                                                     ║"
    echo -e "║                                                                ║"
    echo -e "╚════════════════════════════════════════════════════════════════╝"
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