#!/bin/bash
# ==========================================
# DEV-TOOLS - Herramientas de desarrollo
# ==========================================
# Gestiona herramientas que requieren repositorios externos o root
# (Docker, GitHub CLI). Node/Rust/Go se gestionan via Mise.
# ==========================================

# ─────────────────────────────────────────────────────────────
# Instala GitHub CLI (gh)
#
# Agrega el repositorio oficial e instala la herramienta
# para interactuar con GitHub desde la terminal.
#
# @sideeffects Modifica los repositorios del sistema y fuentes apt/dnf/zypper/apk.
# ─────────────────────────────────────────────────────────────
install_gh_cli() {
    print_step "Instalando GitHub CLI (gh)..."
    
    if command -v gh &> /dev/null; then
        print_info "GitHub CLI ya está instalado"
    else
        ensure_package "curl"
        
        # Instalación específica por distro (gh requiere repos custom a veces)
        case "$OS_TYPE" in
            debian)
                curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | $SUDO_CMD dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
                $SUDO_CMD chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | $SUDO_CMD tee /etc/apt/sources.list.d/github-cli.list > /dev/null
                $SUDO_CMD apt-get update
                $SUDO_CMD apt-get install gh -y
                ;;
            redhat)
                $SUDO_CMD dnf install -y dnf-plugins-core
                $SUDO_CMD dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
                $SUDO_CMD dnf install -y gh
                ;;
            arch)
                $SUDO_CMD pacman -S github-cli --noconfirm
                ;;
            suse)
                $SUDO_CMD zypper addrepo https://cli.github.com/packages/rpm/gh-cli.repo
                $SUDO_CMD zypper ref
                $SUDO_CMD zypper install -y gh
                ;;
            alpine)
                $SUDO_CMD apk add github-cli
                ;;
        esac
        print_success "GitHub CLI instalado"
    fi
    
    gh_auth_login
}

# ─────────────────────────────────────────────────────────────
# Autentica GitHub CLI
#
# Usa el GH_TOKEN guardado en los secretos para autenticar
# GitHub CLI (gh) sin requerir login interactivo por navegador.
#
# @sideeffects Configura credenciales en `~/.config/gh`.
# ─────────────────────────────────────────────────────────────
gh_auth_login() {
    if ! command -v gh &> /dev/null; then return 1; fi
    if gh auth status &> /dev/null; then return 0; fi
    
    print_warning "Autenticando GH CLI..."
    if [ -z "$GH_TOKEN" ]; then decrypt_secrets; fi
    
    if [ -n "$GH_TOKEN" ]; then
        mkdir -p "$HOME/.config/gh"
        echo "$GH_TOKEN" | (unset GH_TOKEN; gh auth login --with-token)
        gh auth setup-git
    else
        gh auth login
    fi
}

# ─────────────────────────────────────────────────────────────
# Instala Docker Engine + Compose
#
# Instala Docker según los repositorios oficiales de cada
# distribución y lo añade al grupo local para no requerir sudo.
#
# @sideeffects Habilita e inicia el demonio de Docker. Modifica grupos.
# ─────────────────────────────────────────────────────────────
install_docker() {
    print_step "Instalando Docker..."
    
    if command -v docker &> /dev/null; then
        print_info "Docker ya está instalado"
        return
    fi
    
    ensure_package "curl"
    ensure_package "ca-certificates"
    ensure_package "gnupg"
    
    case "$OS_TYPE" in
        debian)
            $SUDO_CMD install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO_CMD gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            $SUDO_CMD chmod a+r /etc/apt/keyrings/docker.gpg
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
              $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
              $SUDO_CMD tee /etc/apt/sources.list.d/docker.list > /dev/null
            $SUDO_CMD apt-get update
            $SUDO_CMD apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        redhat)
            $SUDO_CMD dnf -y install dnf-plugins-core
            $SUDO_CMD dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            $SUDO_CMD dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        arch)
            $SUDO_CMD pacman -S docker docker-compose --noconfirm
            ;;
        suse)
            $SUDO_CMD zypper install -y docker docker-compose
            ;;
        alpine)
            $SUDO_CMD apk add docker docker-cli-compose
            $SUDO_CMD rc-update add docker boot
            $SUDO_CMD service docker start
            ;;
    esac
    
    $SUDO_CMD systemctl start docker
    $SUDO_CMD systemctl enable docker
    
    if [ "$(id -u)" -ne 0 ]; then
        $SUDO_CMD usermod -aG docker "$USER"
        print_warning "Docker group updated. Re-login required."
    fi
}

# ─────────────────────────────────────────────────────────────
# Instalación agrupada de Dev Tools
#
# Llama secuencialmente a las rutinas de instalación de gh y docker.
# ─────────────────────────────────────────────────────────────
install_dev_tools_all() {
    install_gh_cli
    install_docker
}
