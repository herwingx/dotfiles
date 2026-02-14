#!/bin/bash
# ==========================================
# DEV-TOOLS - Herramientas de desarrollo
# ==========================================
# Gestiona herramientas que requieren repositorios externos o root
# (Docker, GitHub CLI). Node/Rust/Go se gestionan via Mise.
# ==========================================

# ─────────────────────────────────────────────────────────────
# Instala GitHub CLI (gh)
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
                $SUDO_CMD dnf install gh -y
                ;;
            arch)
                $SUDO_CMD pacman -S github-cli --noconfirm
                ;;
        esac
        print_success "GitHub CLI instalado"
    fi
    
    gh_auth_login
}

# ─────────────────────────────────────────────────────────────
# Autentica GitHub CLI
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
            # Add Docker's official GPG key:
            $SUDO_CMD install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO_CMD gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            $SUDO_CMD chmod a+r /etc/apt/keyrings/docker.gpg

            # Add the repository to Apt sources:
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
    esac
    
    $SUDO_CMD systemctl start docker
    $SUDO_CMD systemctl enable docker
    
    if [ "$(id -u)" -ne 0 ]; then
        $SUDO_CMD usermod -aG docker "$USER"
        print_warning "Docker group updated. Re-login required."
    fi
}

# ─────────────────────────────────────────────────────────────
# Instalación agrupada
# ─────────────────────────────────────────────────────────────
install_dev_tools_all() {
    install_gh_cli
    install_docker
}
