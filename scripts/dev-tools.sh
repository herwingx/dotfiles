#!/bin/bash
# ==============================================================================
# DEV-TOOLS.SH - GitHub CLI & Docker Engine + Compose (Ubuntu & Fedora)
# Soporta DNF4/DNF5 en Fedora y apt en Ubuntu/Debian (Server, Desktop & WSL)
# ==============================================================================

# ─────────────────────────────────────────────────────────────
# Instala y autentica GitHub CLI (gh)
# ─────────────────────────────────────────────────────────────
install_gh_cli() {
    print_step "Verificando GitHub CLI (gh)..."

    if command -v gh &> /dev/null; then
        print_info "GitHub CLI ya está instalado ($(gh --version 2>/dev/null | head -1))."
    elif command -v mise &> /dev/null; then
        print_step "Instalando GitHub CLI vía Mise..."
        mise use --global gh@latest
        path_prepend "$HOME/.local/share/mise/shims"
    else
        ensure_package "curl"
        case "$OS_TYPE" in
            debian)
                $SUDO_CMD install -m 0755 -d /etc/apt/keyrings
                curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | $SUDO_CMD tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
                $SUDO_CMD chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
                    $SUDO_CMD tee /etc/apt/sources.list.d/github-cli.list > /dev/null
                run_pkg_index_update
                $PKG_INSTALL_CMD gh
                ;;
            redhat)
                $PKG_INSTALL_CMD gh
                ;;
        esac
        print_success "GitHub CLI instalado."
    fi

    gh_auth_login
}

# ─────────────────────────────────────────────────────────────
# Autentica GitHub CLI usando Proton Pass (o salta en Guest Mode)
# ─────────────────────────────────────────────────────────────
gh_auth_login() {
    if ! command -v gh &> /dev/null; then
        return 0
    fi

    if (unset GH_TOKEN GITHUB_TOKEN; gh auth status &>/dev/null); then
        print_success "GitHub CLI ya está autenticado."
        gh auth setup-git 2>/dev/null || true
        return 0
    fi

    if [ -z "${GH_TOKEN:-}" ]; then
        load_secrets
    fi

    if [ -n "${GH_TOKEN:-}" ]; then
        print_step "Autenticando GitHub CLI con GH_TOKEN..."
        mkdir -p "$HOME/.config/gh"
        if echo "$GH_TOKEN" | (unset GH_TOKEN GITHUB_TOKEN; gh auth login --with-token); then
            (unset GH_TOKEN GITHUB_TOKEN; gh auth setup-git)
            print_success "GitHub CLI autenticado y vinculado con Git."
            return 0
        fi
    fi

    if [ "${GUEST_MODE:-}" == "true" ] || [ "${AUTO_INSTALL:-}" == "true" ]; then
        print_info "Guest Mode: omitiendo login de GitHub CLI (ejecuta './install.sh --secrets' cuando tengas tus credenciales)."
        return 0
    fi

    if ui_confirm "¿Deseas autenticar GitHub CLI (gh auth login) interactivamente ahora?"; then
        gh auth login && gh auth setup-git
    else
        print_info "Autenticación de GitHub CLI pospuesta."
    fi
}

# ─────────────────────────────────────────────────────────────
# Instala Docker Engine + Buildx + Compose en Ubuntu/Debian y Fedora
# Compatible con Fedora 41-44+ (DNF5) y Ubuntu Server/Desktop.
# ─────────────────────────────────────────────────────────────
install_docker() {
    print_header "DOCKER ENGINE & COMPOSE SETUP (NATIVO SIN OVERHEAD)"

    # En WSL2, si Docker Desktop de Windows ya expone el socket en esta distro, respetarlo
    if [ "$IS_WSL" == "true" ] && [ -S /var/run/docker.sock ] && command -v docker &>/dev/null; then
        if docker info 2>/dev/null | grep -qi "Docker Desktop"; then
            print_success "Docker Desktop (WSL2 Integration) detectado y activo."
            return 0
        fi
    fi

    if command -v docker &> /dev/null; then
        print_info "Docker Engine ya está instalado ($(docker --version 2>/dev/null))."
    else
        ensure_package "curl"
        ensure_package "ca-certificates"

        case "$OS_TYPE" in
            debian)
                ensure_package "gnupg" "gpg"
                $SUDO_CMD install -m 0755 -d /etc/apt/keyrings

                local docker_distro="ubuntu"
                local codename=""
                # shellcheck disable=SC1091
                codename="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"
                if [ "$OS_ID" == "debian" ]; then
                    docker_distro="debian"
                fi

                curl -fsSL "https://download.docker.com/linux/${docker_distro}/gpg" | \
                    $SUDO_CMD gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
                $SUDO_CMD chmod a+r /etc/apt/keyrings/docker.gpg

                echo \
                  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${docker_distro} \
                  ${codename} stable" | \
                  $SUDO_CMD tee /etc/apt/sources.list.d/docker.list > /dev/null

                run_pkg_index_update
                $PKG_INSTALL_CMD docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                ;;
            redhat)
                # Compatible tanto con DNF4 como con DNF5 (Fedora 41-44+)
                local repo_os="fedora"
                [[ "$OS_ID" =~ ^(rhel|centos|almalinux|rocky)$ ]] && repo_os="centos"

                print_step "Configurando repositorio oficial de Docker (${repo_os})..."
                curl -fsSL "https://download.docker.com/linux/${repo_os}/docker-ce.repo" | \
                    $SUDO_CMD tee /etc/yum.repos.d/docker-ce.repo > /dev/null

                $PKG_INSTALL_CMD docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                ;;
        esac
        print_success "Docker Engine + CLI + Buildx + Compose instalados."
    fi

    # Configurar rotación automática de logs de contenedores (evita que los logs llenen el disco)
    if [ ! -f /etc/docker/daemon.json ]; then
        print_step "Configurando rotación de logs de Docker (/etc/docker/daemon.json)..."
        $SUDO_CMD mkdir -p /etc/docker
        $SUDO_CMD tee /etc/docker/daemon.json >/dev/null <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
    fi

    # Iniciar y habilitar servicio si systemd está activo
    if command -v systemctl &>/dev/null && systemctl is-system-running &>/dev/null; then
        $SUDO_CMD systemctl enable --now docker >/dev/null 2>&1 || true
        print_success "Servicio docker.service activo y habilitado."
    elif command -v service &>/dev/null; then
        $SUDO_CMD service docker start >/dev/null 2>&1 || true
    fi

    # Asegurar que el usuario pertenezca al grupo docker
    if [ "$(id -u)" -ne 0 ] && getent group docker &>/dev/null; then
        if ! id -nG "$USER" | grep -qw "docker"; then
            $SUDO_CMD usermod -aG docker "$USER"
            print_warning "Usuario '$USER' añadido al grupo 'docker' (requiere relogin para aplicar)."
        fi
    fi

    print_info "Atajos listos: 'd' (docker), 'dc' (docker compose), 'ld' (lazydocker TUI)."
}

# ─────────────────────────────────────────────────────────────
# Instala todas las herramientas de desarrollo pesadas
# ─────────────────────────────────────────────────────────────
install_dev_tools_all() {
    install_gh_cli
    install_docker
}
