#!/bin/bash
# ==========================================
# SYSTEM - Actualización y paquetes del sistema
# ==========================================
# Funciones para actualizar el sistema operativo e instalar
# paquetes base y herramientas avanzadas de terminal.
# Soporta: Debian/Ubuntu, Fedora/RHEL, Arch Linux
# ==========================================

# ─────────────────────────────────────────────────────────────
# Actualiza el sistema operativo según la distribución detectada.
# Ejecuta upgrade y autoremove para limpiar paquetes huérfanos.
# ─────────────────────────────────────────────────────────────
# ─────────────────────────────────────────────────────────────
# Genera y configura locales (Fix para LXC/Docker)
# ─────────────────────────────────────────────────────────────
fix_locales() {
    if [ -f /etc/debian_version ]; then
        echo -e "${CYAN}   Verificando locales...${NC}"
        if ! locale -a | grep -q "en_US.utf8"; then
            echo -e "${YELLOW}   ! Locales faltantes. Generando en_US.UTF-8...${NC}"
            $SUDO_CMD apt-get install -y locales >/dev/null 2>&1
            $SUDO_CMD locale-gen en_US.UTF-8
            $SUDO_CMD update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
            export LANG=en_US.UTF-8
            export LC_ALL=en_US.UTF-8
            echo -e "${CYAN}   ✓ Locales generados${NC}"
        fi
    fi
}

# ─────────────────────────────────────────────────────────────
# Helper: Gestión robusta de bloques en .bashrc
# Modo: "top", "bottom", "before-ble" (antes de ble-attach)
# ─────────────────────────────────────────────────────────────
update_bashrc_block() {
    local name="$1"
    local content="$2"
    local mode="$3"
    local bashrc="$HOME/.bashrc"
    
    local start="<!-- BEGIN_${name} -->"
    local end="<!-- END_${name} -->"
    
    # 1. Limpiar bloque existente
    sed -i "/$start/,/$end/d" "$bashrc"
    
    # 2. Preparar nuevo bloque
    local block="# $start
$content
# $end"

    # 3. Insertar según modo
    if [ "$mode" == "top" ]; then
        # Usar archivos temporales para evitar problemas de buffer/truncado con cat
        cp "$bashrc" "$bashrc.tmp"
        echo "$block" > "$bashrc"
        echo "" >> "$bashrc"
        cat "$bashrc.tmp" >> "$bashrc"
        rm -f "$bashrc.tmp"
        
    elif [ "$mode" == "before-ble" ]; then
        # 1. Prioridad: Buscar marcador de inicio de bloque BLE (Evita anidación)
        local anchor=$(grep -n "<!-- BEGIN_BLE_ATTACH -->" "$bashrc" | head -n1 | cut -d: -f1)
        
        # 2. Fallback: Buscar comando ble-attach (evitando comentarios)
        if [ -z "$anchor" ]; then
             anchor=$(grep -n "ble-attach" "$bashrc" | grep -v "^#" | head -n1 | cut -d: -f1)
        fi
        
        if [ -n "$anchor" ]; then
             local head_lines=$((anchor - 1))
             
             cp "$bashrc" "$bashrc.tmp"
             if [ "$head_lines" -ge 0 ]; then
                 head -n "$head_lines" "$bashrc.tmp" > "$bashrc"
             else
                 > "$bashrc"
             fi
             
             echo "" >> "$bashrc"
             echo "$block" >> "$bashrc"
             echo "" >> "$bashrc"
             tail -n "+$anchor" "$bashrc.tmp" >> "$bashrc"
             rm -f "$bashrc.tmp"
        else
            # Si no se encuentra, append
            echo "" >> "$bashrc"
            echo "$block" >> "$bashrc"
        fi
        
    else # bottom
        echo "" >> "$bashrc"
        echo "$block" >> "$bashrc"
    fi
}

update_system() {
    echo -e "${GREEN}>>> Actualizando el sistema...${NC}"
    
    if [ -f /etc/debian_version ]; then
        echo -e "${CYAN}   Detectado: Debian/Ubuntu (apt)${NC}"
        fix_locales
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

# ─────────────────────────────────────────────────────────────
# Instala paquetes esenciales del sistema.
# Incluye: git, curl, htop, btop, vim, tmux, fzf, ranger, rclone, etc.
# También instala herramientas avanzadas y configura aliases.
# ─────────────────────────────────────────────────────────────
install_packages() {
    echo -e "${GREEN}>>> Instalando paquetes del sistema y herramientas de terminal...${NC}"
    
    # Paquetes comunes
    COMMON_PACKAGES=(
        "git" "curl" "wget" "htop" "btop" "vim" "unzip" "tree" 
        "net-tools" "tmux" "fzf" "ranger" "mc" "rclone"
        "make" "gawk" "micro" "tldr" "tar"
    )
    
    if [ -f /etc/debian_version ]; then
        echo -e "${CYAN}   Detectado: Debian/Ubuntu (apt)${NC}"
        $SUDO_CMD apt-get update -y
        # Debian names
        DEB_PACKAGES=("${COMMON_PACKAGES[@]}" "neofetch" "gcc" "xz-utils" "build-essential" "dnsutils" "w3m-img" "age")
        $SUDO_CMD apt-get install -y "${DEB_PACKAGES[@]}"
        
    elif [ -f /etc/redhat-release ]; then
        echo -e "${CYAN}   Detectado: Fedora/RHEL (dnf)${NC}"
        # Fedora names: neofetch -> fastfetch, xz-utils -> xz, dnsutils -> bind-utils
        RPM_PACKAGES=("${COMMON_PACKAGES[@]}" "fastfetch" "gcc" "xz" "bind-utils" "w3m-img" "age")
        
        # DNF5 support: 'groupinstall' is deprecated in favor of 'install @Group' or 'group install'
        # We try strict 'install @' syntax which works on both dnf4 and dnf5
        echo -e "${CYAN}   Instalando Development Tools...${NC}"
        $SUDO_CMD dnf install -y @development-tools --skip-broken 2>/dev/null || echo -e "${YELLOW}   ! Skip development tools group (check manually)${NC}"
        
        $SUDO_CMD dnf install -y "${RPM_PACKAGES[@]}" --skip-broken
        
    elif [ -f /etc/arch-release ]; then
        echo -e "${CYAN}   Detectado: Arch Linux (pacman)${NC}"
        ARCH_PACKAGES=("${COMMON_PACKAGES[@]}" "fastfetch" "gcc" "xz" "base-devel" "bind" "w3m" "age")
        $SUDO_CMD pacman -Syu --noconfirm "${ARCH_PACKAGES[@]}"
    else
        echo -e "${RED}>>> Sistema no soportado para instalación automática${NC}"
        echo -e "${YELLOW}   Instala manualmente: ${COMMON_PACKAGES[*]}${NC}"
        return
    fi
    
    # Configurar ranger si está instalado
    if command -v ranger &> /dev/null; then
        if [ ! -d "$HOME/.config/ranger" ]; then
            echo -e "${CYAN}   Configurando ranger...${NC}"
            ranger --copy-config=all
        fi
    fi
    
    echo -e "${CYAN}   ✓ Paquetes base instalados${NC}"

    # Actualizar base de datos de tldr (si se instaló)
    if command -v tldr &> /dev/null; then
        echo -e "${CYAN}   Actualizando base de datos tldr...${NC}"
        tldr --update &>/dev/null || true
    fi
    
    install_bash_aliases
    install_modern_tools
    
    echo -e "${CYAN}   ✓ Sistema completo configurado${NC}"
}

# ─────────────────────────────────────────────────────────────
# Vincula el archivo .bash_aliases desde config/ al home.
# Crea backup si existe un archivo previo (no symlink).
# ─────────────────────────────────────────────────────────────
install_bash_aliases() {
    echo -e "${GREEN}>>> Vinculando Bash Aliases...${NC}"
    ALIAS_FILE="$HOME/.bash_aliases"
    [ -f "$ALIAS_FILE" ] && [ ! -L "$ALIAS_FILE" ] && mv "$ALIAS_FILE" "$ALIAS_FILE.backup"
    ln -sf "$DOTFILES_DIR/config/.bash_aliases" "$ALIAS_FILE"
    echo -e "${CYAN}   ✓ Aliases configurados${NC}"
    
    # Asegurar que .bashrc cargue .bash_aliases de forma ROBUSTA
    BASHRC="$HOME/.bashrc"
    
    CONTENT=$(cat <<EOF
# Cargar aliases personales
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
EOF
)
    # Limpieza legacy
    sed -i '/source ~\/.bash_aliases/d' "$BASHRC"
    sed -i '/\. ~\/.bash_aliases/d' "$BASHRC"

    update_bashrc_block "ALIASES" "$CONTENT" "before-ble"
    
    # Limpiar variables de entorno hardcodeadas problemáticas (GitHub Token viejo)
    # Esto soluciona que 'gh auth login' se pierda al abrir nueva terminal si el token en bashrc es inválido
    sed -i '/export GITHUB_PERSONAL_ACCESS_TOKEN=/d' "$BASHRC"
    sed -i '/export GITHUB_TOKEN=/d' "$BASHRC"
    sed -i '/# GitHub Token (Verify if this is current)/d' "$BASHRC"

    # Limpiar PATH en WSL y asegurar PATH universal
    configure_wsl_path
    ensure_path
}

# ─────────────────────────────────────────────────────────────
# Configura el PATH en WSL para excluir binarios de Windows.
# Esto evita conflictos como el de Gemini detectando nvm4w.
# ─────────────────────────────────────────────────────────────
configure_wsl_path() {
    # Detectar si estamos en WSL
    if [ ! -f /proc/version ] || ! grep -qi microsoft /proc/version; then
        return  # No estamos en WSL, salir
    fi
    
    echo -e "${CYAN}   Detectado WSL. Limpiando PATH de rutas de Windows...${NC}"
    
    BASHRC="$HOME/.bashrc"
    
    # Verificar si ya existe la configuración
    if grep -q "# WSL: Limpiar PATH de Windows" "$BASHRC"; then
        echo -e "${YELLOW}   ! PATH de WSL ya configurado${NC}"
        return
    fi
    
    # Agregar al .bashrc la limpieza de PATH al PRINCIPIO (Solo si no existe)
    # Bloque de configuración WSL PATH
    CONTENT=$(cat <<EOF
# WSL: Limpiar PATH de Windows (evitar conflictos con binarios .exe)
if grep -qi microsoft /proc/version 2>/dev/null; then
    # Filtrar rutas de /mnt/* del PATH
    NEW_PATH=\$(echo "\$PATH" | tr ":" "\n" | grep -v "^/mnt/" | tr "\n" ":" | sed "s/:\$//")
    export PATH="\$NEW_PATH"
fi
EOF
)
    # Limpieza legacy
    sed -i '/# WSL: Limpiar PATH de Windows/d' "$BASHRC"

    update_bashrc_block "WSL_PATH" "$CONTENT" "top"
    
    echo -e "${CYAN}   ✓ PATH verificado${NC}"
    echo -e "${YELLOW}   ⚠️  Recarga tu shell (source ~/.bashrc) para aplicar cambios${NC}"
}

# ─────────────────────────────────────────────────────────────
# Asegura que /usr/local/bin esté en el PATH (Crítico para oh-my-posh/LXC)
# ─────────────────────────────────────────────────────────────
ensure_path() {
    BASHRC="$HOME/.bashrc"
    
    # Solo agregar si no se detecta ya una configuración explícita de este tipo
    # Bloque PATH universal
    CONTENT='export PATH="$HOME/.local/bin:$HOME/.atuin/bin:/usr/local/bin:$PATH"'

    sed -i '/export PATH="\$HOME\/.local\/bin:\$HOME\/.atuin\/bin:\/usr\/local\/bin:\$PATH"/d' "$BASHRC"

    update_bashrc_block "PATH_FIX" "$CONTENT" "before-ble"
}


# ─────────────────────────────────────────────────────────────
# Instala herramientas "Modern Unix" (Rust-based replacements)
# Incluye: zoxide, bat, delta, ripgrep, lsd, etc.
# ─────────────────────────────────────────────────────────────
install_modern_tools() {
    echo -e "${GREEN}>>> Instalando Modern Unix Tools...${NC}"

    # 1. Zoxide (Smarter cd)
    if ! command -v zoxide &> /dev/null; then
        echo -e "${CYAN}   Instalando zoxide...${NC}"
        
        # Intentar primero por gestor de paquetes (más fiable en LXC)
        if [ -f /etc/debian_version ]; then
            $SUDO_CMD apt-get install -y zoxide 2>/dev/null
        elif [ -f /etc/redhat-release ]; then
            $SUDO_CMD dnf install -y zoxide 2>/dev/null
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S zoxide --noconfirm 2>/dev/null
        fi

        # Si aún no existe (versión vieja de distro), usar el script oficial
        if ! command -v zoxide &> /dev/null; then
            echo -e "${YELLOW}   ! No disponible en repo. Usando script de instalación...${NC}"
            curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
        fi


    else
        echo -e "${YELLOW}   ! zoxide ya existe${NC}"
    fi

    # Configurar en .bashrc con marcadores (SIEMPRE, incluso si ya existía)
    CONTENT=$(cat <<EOF
# Zoxide (Smarter cd)
if command -v zoxide &>/dev/null; then
    eval "\$(zoxide init bash)"
fi
EOF
)
    sed -i '/zoxide init bash/d' "$BASHRC"
    update_bashrc_block "ZOXIDE" "$CONTENT" "before-ble"
    
    # Alias cd=z (Gestionado en .bash_aliases, solo log informativo)
    if ! grep -q 'alias cd="z"' "$HOME/.bash_aliases"; then
            echo -e "${CYAN}   ℹ Alias cd=z gestionado en .bash_aliases${NC}"
    fi
    
    echo -e "${CYAN}   ✓ zoxide configurado${NC}"

    # 2. Bat (Better cat)
    if ! command -v bat &> /dev/null && ! command -v batcat &> /dev/null; then
        echo -e "${CYAN}   Instalando bat...${NC}"
        if [ -f /etc/debian_version ]; then
            $SUDO_CMD apt-get install -y bat
            mkdir -p ~/.local/bin
            ln -sf /usr/bin/batcat ~/.local/bin/bat
        elif [ -f /etc/redhat-release ]; then
            $SUDO_CMD dnf install -y bat
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S bat --noconfirm
        fi
        echo -e "${CYAN}   ✓ bat instalado${NC}"
    else
        echo -e "${YELLOW}   ! bat ya existe${NC}"
    fi

    # 3. Ripgrep (Faster grep)
    if ! command -v rg &> /dev/null; then
        echo -e "${CYAN}   Instalando ripgrep...${NC}"
        if [ -f /etc/debian_version ]; then
            $SUDO_CMD apt-get install -y ripgrep
        elif [ -f /etc/redhat-release ]; then
            $SUDO_CMD dnf install -y ripgrep
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S ripgrep --noconfirm
        fi
        echo -e "${CYAN}   ✓ ripgrep instalado${NC}"
    else
        echo -e "${YELLOW}   ! ripgrep ya existe${NC}"
    fi
    
    # 4. Git Delta (Better diff)
    if ! command -v delta &> /dev/null; then
        echo -e "${CYAN}   Instalando git-delta...${NC}"
        INSTALLED=false
        
        # Try package manager first
        if [ -f /etc/debian_version ]; then
             : # Skip repo on debian usually old
        elif [ -f /etc/redhat-release ]; then
             $SUDO_CMD dnf install -y git-delta 2>/dev/null && INSTALLED=true || $SUDO_CMD dnf install -y delta 2>/dev/null && INSTALLED=true
        elif [ -f /etc/arch-release ]; then
             $SUDO_CMD pacman -S git-delta --noconfirm 2>/dev/null && INSTALLED=true
        fi
        
        if [ "$INSTALLED" = false ]; then
             if command -v cargo &> /dev/null; then
                 cargo install git-delta
             else
                 DELTA_VERSION="0.16.5"
                 if [ -f /etc/debian_version ]; then
                      wget -q "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb" -O /tmp/delta.deb
                      $SUDO_CMD dpkg -i /tmp/delta.deb 2>/dev/null
                      rm -f /tmp/delta.deb
                 else
                      # Universal Linux binary
                      echo -e "${YELLOW}   Descargando binario de git-delta...${NC}"
                      wget -q "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl.tar.gz" -O /tmp/delta.tar.gz
                      tar -xzf /tmp/delta.tar.gz -C /tmp
                      $SUDO_CMD mv "/tmp/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl/delta" /usr/local/bin/delta
                      $SUDO_CMD chmod +x /usr/local/bin/delta
                      rm -rf /tmp/delta.tar.gz "/tmp/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl"
                 fi
             fi
        fi

        # Config
        if command -v delta &> /dev/null; then
            git config --global core.pager "delta"
            git config --global interactive.diffFilter "delta --color-only"
            git config --global delta.navigate true
            echo -e "${CYAN}   ✓ delta configurado${NC}"
        fi
    fi

    # 5. LSD (Modern ls)
    if ! command -v lsd &> /dev/null; then
        echo -e "${CYAN}   Instalando lsd...${NC}"
        if [ -f /etc/debian_version ]; then
            LSD_VERSION="1.1.5"
            wget -q "https://github.com/lsd-rs/lsd/releases/download/v${LSD_VERSION}/lsd_${LSD_VERSION}_amd64.deb" -O /tmp/lsd.deb
            $SUDO_CMD dpkg -i /tmp/lsd.deb; rm -f /tmp/lsd.deb
        elif [ -f /etc/redhat-release ]; then
            $SUDO_CMD dnf install lsd -y 2>/dev/null || {
                LSD_VERSION="1.1.5"
                wget -q "https://github.com/lsd-rs/lsd/releases/download/v${LSD_VERSION}/lsd-${LSD_VERSION}-x86_64-unknown-linux-gnu.tar.gz" -O /tmp/lsd.tar.gz
                tar -xzf /tmp/lsd.tar.gz -C /tmp
                $SUDO_CMD mv "/tmp/lsd-${LSD_VERSION}-x86_64-unknown-linux-gnu/lsd" /usr/local/bin/lsd
                $SUDO_CMD chmod +x /usr/local/bin/lsd
                rm -rf /tmp/lsd.tar.gz "/tmp/lsd-${LSD_VERSION}-x86_64-unknown-linux-gnu"
            }
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S lsd --noconfirm
        fi
        echo -e "${CYAN}   ✓ lsd instalado${NC}"
    else
        echo -e "${YELLOW}   ! lsd ya está instalado${NC}"
    fi
    
    # Lazydocker
    if ! command -v lazydocker &> /dev/null; then
        echo -e "${CYAN}   Instalando lazydocker...${NC}"
        curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
    else
        echo -e "${YELLOW}   ! lazydocker ya está instalado${NC}"
    fi
    
    # Ctop
    if ! command -v ctop &> /dev/null; then
        echo -e "${CYAN}   Instalando ctop...${NC}"
        if [ -f /etc/debian_version ] || [ -f /etc/redhat-release ]; then
            $SUDO_CMD wget -q https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64 -O /usr/local/bin/ctop
            $SUDO_CMD chmod +x /usr/local/bin/ctop
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S ctop --noconfirm
        fi
        echo -e "${CYAN}   ✓ ctop instalado${NC}"
    else
        echo -e "${YELLOW}   ! ctop ya está instalado${NC}"
    fi
    
    # Gping
    if ! command -v gping &> /dev/null; then
        echo -e "${CYAN}   Instalando gping...${NC}"
        if [ -f /etc/debian_version ]; then
            echo "deb [signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian/ stable main" | $SUDO_CMD tee /etc/apt/sources.list.d/azlux.list >/dev/null
            $SUDO_CMD wget -O /usr/share/keyrings/azlux-archive-keyring.gpg  https://azlux.fr/repo.gpg
            $SUDO_CMD apt-get update && $SUDO_CMD apt-get install -y gping
        elif [ -f /etc/redhat-release ]; then
            $SUDO_CMD dnf install gping -y 2>/dev/null || {
                # Binary fallback - Updated URL
                echo -e "${YELLOW}   ! gping no está en repos, intentando binario...${NC}"
                GPING_URL="https://github.com/orf/gping/releases/download/gping-v1.16.1/gping-Linux-x86_64.tar.gz"
                wget -q "$GPING_URL" -O /tmp/gping.tar.gz
                
                if [ -s /tmp/gping.tar.gz ]; then
                    tar -xzf /tmp/gping.tar.gz -C /tmp
                    $SUDO_CMD mv /tmp/gping /usr/local/bin/gping
                    $SUDO_CMD chmod +x /usr/local/bin/gping
                    rm -f /tmp/gping.tar.gz
                    echo -e "${CYAN}   ✓ gping instalado (binario)${NC}"
                else
                    echo -e "${RED}   ✗ Falló descarga de gping${NC}"
                fi
            }
        elif [ -f /etc/arch-release ]; then
            $SUDO_CMD pacman -S gping --noconfirm
        fi
        
        if command -v gping &> /dev/null; then
             echo -e "${CYAN}   ✓ gping verificado${NC}"
        fi
    else
        echo -e "${YELLOW}   ! gping ya está instalado${NC}"
    fi

    # Atuin
    install_atuin

    # Oh My Posh
    install_oh_my_posh

    # Ble.sh (Bash Line Editor) - Debe ir AL FINAL
    # Se ha movido a instaladores principales para garantizar orden (install_all / install_system_all)
    # install_blesh

    # Tmux Configuration (Premium)
    if [ -f "$DOTFILES_DIR/config/.tmux.conf" ]; then
        ln -sf "$DOTFILES_DIR/config/.tmux.conf" "$HOME/.tmux.conf"
        echo -e "${CYAN}   ✓ tmux.conf enlazado${NC}"
    fi
    
    # Configuración de Google Antigravity (WSL Fix)
    install_antigravity_fix

    echo -e "${CYAN}   ✓ Herramientas Modern Unix instaladas${NC}"
    echo -e "${CYAN}   Disponibles: zoxide, bat, rg, delta, atuin, ble.sh, tmux, agy${NC}"
}

# ─────────────────────────────────────────────────────────────
# Configura Google Antigravity (agy) en WSL.
# - Crea symlink al ejecutable de Windows.
# - Parchea el archivo de lanzamiento para corregir el bug de ID de extensión.
# ─────────────────────────────────────────────────────────────
install_antigravity_fix() {
    # Solo ejecutar en WSL
    if ! grep -qi microsoft /proc/version 2>/dev/null; then
        return
    fi

    echo -e "${GREEN}>>> Configurando Google Antigravity (agy) para WSL...${NC}"
    
    # 1. Detectar usuario de Windows dinámicamente (Estrategia Robusta)
    WIN_USER=""
    
    # Método A: cmd.exe en el PATH
    if command -v cmd.exe &> /dev/null; then
        # Usamos tail -n1 para tomar solo la última línea (el usuario) y evitar warnings de rutas UNC
        WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tail -n1 | tr -d '\r')
    fi
    
    # Método B: Ruta absoluta de cmd.exe (si PATH falla)
    if [ -z "$WIN_USER" ] && [ -f "/mnt/c/Windows/System32/cmd.exe" ]; then
        WIN_USER=$(/mnt/c/Windows/System32/cmd.exe /c "echo %USERNAME%" 2>/dev/null | tail -n1 | tr -d '\r')
    fi
    
    # Método C: Escaneo de /mnt/c/Users (Heurística final)
    if [ -z "$WIN_USER" ] && [ -d "/mnt/c/Users" ]; then
        # Buscamos el primer directorio que parezca un usuario real
        for user_dir in /mnt/c/Users/*; do
            [ -d "$user_dir" ] || continue
            dirname=$(basename "$user_dir")
            case "$dirname" in
                "Public"|"Default"|"All Users"|"Default User"|"desktop.ini") continue ;;
                *) WIN_USER="$dirname"; break ;;
            esac
        done
    fi
    
    if [ -n "$WIN_USER" ]; then
        # Ruta estándar de instalación en Windows (accedida desde /mnt/c)
        AGY_PATH="/mnt/c/Users/$WIN_USER/AppData/Local/Programs/Antigravity/bin/antigravity"
        
        if [ -f "$AGY_PATH" ]; then
            # 2. Crear Symlink en ~/.local/bin
            # Forzamos la creación del directorio por si acaso
            mkdir -p "$HOME/.local/bin"
            
            # Eliminamos link previo si existe y creamos uno nuevo
            rm -f "$HOME/.local/bin/agy"
            ln -s "$AGY_PATH" "$HOME/.local/bin/agy"
            echo -e "${CYAN}   ✓ Symlink 'agy' vinculado al ejecutable de Windows${NC}"
            
            # 3. Parchear el bug de WSL_EXT_ID (Fix Smart)
            # Solo parcheamos si detectamos que la estructura de archivos soporta el nuevo ID
            # o si el usuario ya lo tenía parcheado.
            
            BASE_DIR="$(dirname "$(dirname "$AGY_PATH")")"
            EXT_DIR="$BASE_DIR/resources/app/extensions"
            
            # Lógica ULTRA-SEGURA para evitar "No such file"
            # Solo aplicamos el parche si la carpeta de destino EXISTE FÍSICAMENTE.
            # Si no existe, nos aseguramos de que el ID sea el original (legacy) para que funcione siempre.
            
            if [ -d "$EXT_DIR/$NEW_EXT_FOLDER" ]; then
                # La carpeta premium existe, podemos activar el modo nativo
                if grep -q "WSL_EXT_ID=\"ms-vscode-remote.remote-wsl\"" "$AGY_PATH"; then
                     echo -e "${GREEN}   ✓ Carpeta nativa detectada. Activando modo optimizado (Google ID)...${NC}"
                     cp "$AGY_PATH" "${AGY_PATH}.bak"
                     sed -i 's/WSL_EXT_ID="ms-vscode-remote.remote-wsl"/WSL_EXT_ID="google.antigravity-remote-wsl"/' "$AGY_PATH"
                else
                     echo -e "${CYAN}   ✓ Antigravity ya está optimizado (Modo Nativo)${NC}"
                fi
            else
                # La carpeta nueva NO existe. Debemos usar el modo legacy (Microsoft ID)
                if grep -q "WSL_EXT_ID=\"google.antigravity-remote-wsl\"" "$AGY_PATH"; then
                     echo -e "${YELLOW}   ! Carpeta nativa no encontrada. Revertiendo a modo compatibilidad...${NC}"
                     echo -e "${YELLOW}     (Esto evita el error 'wslCode.sh not found')${NC}"
                     sed -i 's/WSL_EXT_ID="google.antigravity-remote-wsl"/WSL_EXT_ID="ms-vscode-remote.remote-wsl"/' "$AGY_PATH"
                     echo -e "${GREEN}   ✓ Restaurado modo compatibilidad. 'agy' funcionará por red.${NC}"
                else
                     echo -e "${CYAN}   ✓ Configuración compatible verificada (Modo Red)${NC}"
                fi
                # Mensaje educativo
                echo -e "${DIM}     Tip: Para modo nativo, copia 'ms-vscode-remote...' a 'antigravity-remote-wsl' en Windows.${NC}"
            fi

        else
            echo -e "${RED}   ✗ No se encontró Antigravity en: $AGY_PATH${NC}"
            echo -e "${YELLOW}     Verifica que esté instalado en la ruta por defecto.${NC}"
        fi
    else
        echo -e "${RED}   ✗ No se pudo detectar el usuario de Windows automáticamente${NC}"
    fi
}


# ─────────────────────────────────────────────────────────────
# Instala Ble.sh (Syntax Highlighting & Auto-suggestions for Bash)
# ─────────────────────────────────────────────────────────────
install_blesh() {
    echo -e "${GREEN}>>> Instalando Ble.sh (Bash Line Editor)...${NC}"
    
    BLESH_DIR="$HOME/.local/share/blesh"
    
    # 1. Instalación/Compilación robusta
    if [ ! -d "$BLESH_DIR" ] || [ ! -f "$BLESH_DIR/ble.sh" ]; then
         # Verificar dependencias críticas antes de intentar
         if ! command -v make &> /dev/null || ! command -v gawk &> /dev/null; then
             echo -e "${RED}   ✗ Faltan dependencias para compilar ble.sh (make, gawk)${NC}"
             echo -e "${YELLOW}   Intentando instalar dependencias faltantes...${NC}"
             install_packages
         fi

         echo -e "${CYAN}   Clonando y compilando ble.sh...${NC}"
         rm -rf /tmp/ble.sh
         if ! git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git /tmp/ble.sh; then
             echo -e "${RED}   ✗ Error al clonar ble.sh${NC}"
             return 1
         fi

         # Compilar e instalar (usando PREFIX local)
         if make -C /tmp/ble.sh install PREFIX=~/.local; then
             echo -e "${CYAN}   ✓ Ble.sh instalado exitosamente${NC}"
         else
             echo -e "${RED}   ✗ Error al compilar ble.sh. Verifica: make, gcc, gawk.${NC}"
             rm -rf /tmp/ble.sh
             return 1
         fi
         rm -rf /tmp/ble.sh
    fi

    # 2. Configurar estilos y comportamiento (.blerc)
    # Añadimos opciones para silenciar mensajes técnicos y mejorar compatibilidad
    echo -e "${CYAN}   Configurando .blerc (Estabilidad y Silencio)...${NC}"
    cat > "$HOME/.blerc" <<'EOF'
# Función para establecer opciones de forma segura (sin errores si no existen)
_safe_bleopt() {
    local opt=$1 val=$2
    if bleopt "$opt" >/dev/null 2>&1; then
        bleopt "$opt=$val"
    fi
}

# DESACTIVAR modo multilínea - Enter siempre ejecuta el comando
ble-bind -f 'C-m' 'accept-line'
ble-bind -f 'RET' 'accept-line'

# Configuración de autocompletado
# Reactivamos el autocompletado automático (necesario para que TAB responda ágilmente)
_safe_bleopt complete_auto_complete 1
_safe_bleopt complete_auto_history 1
_safe_bleopt complete_ambiguous 1

# Menú de completado limpio (solo con TAB)
_safe_bleopt complete_menu_style align-nowrap

# Ocultar el mensaje de estado de salida [ble: exit XXX]
_safe_bleopt exec_exit_status ""
_safe_bleopt print_exit_status 0
bleopt exec_elapsed_mark=

# Colores limpios (syntax highlighting sigue activo)
if [[ ${BLE_VERSION-} ]]; then
    ble-face -s syntax_error fg=196,bg=default
    ble-face -s syntax_varname fg=208
    ble-face -s syntax_quoted fg=107
    ble-face -s command_builtin fg=green
    ble-face -s command_file fg=cyan
    # Autocompletado sutil (transparente, sin subrayado)
    ble-face -s auto_complete fg=242,bg=default,ul=none
    # Selección al insertar con TAB (quitamos el fondo blanco)
    ble-face -s region_insert fg=default,bg=237
fi
EOF

    # 3. Configurar .bashrc de forma segura (preservando otros bloques)
    if [ -f "$BLESH_DIR/ble.sh" ]; then
        BASHRC="$HOME/.bashrc"
        
        # Limpieza legacy SOLO de líneas de ble.sh (no bloques completos)
        sed -i '/source ~\/.*ble.sh/d' "$BASHRC"
        # NO borrar ble-attach aquí porque lo necesitamos como ancla para otros bloques
        sed -i '/# Ble.sh attach/d' "$BASHRC"
        sed -i '/: # .*ble.sh.*/d' "$BASHRC"

        # Contenido de los bloques (sin marcadores, el helper los añade)
        BLE_SOURCE_CONTENT='# 1. Ble.sh Source (Must be at the start for proper functionality)
[[ $- == *i* && -f ~/.local/share/blesh/ble.sh ]] && source ~/.local/share/blesh/ble.sh --noattach 2>/dev/null'

        BLE_ATTACH_CONTENT='# 6. Ble.sh Attach (Must be the last line)
[[ ${BLE_VERSION-} ]] && ble-attach'

        # Usar el helper para insertar/actualizar bloques de forma segura
        update_bashrc_block "BLE_SOURCE" "$BLE_SOURCE_CONTENT" "top"
        update_bashrc_block "BLE_ATTACH" "$BLE_ATTACH_CONTENT" "bottom"
        
        echo -e "${CYAN}   ✓ .bashrc configurado (Source al inicio, Attach al final)${NC}"
    else
        echo -e "${RED}   ✗ No se encontró ble.sh tras la instalación${NC}"
    fi
}

# ─────────────────────────────────────────────────────────────
# Instala Atuin (Historial de Shell Mágico)
# ─────────────────────────────────────────────────────────────
install_atuin() {
    echo -e "${GREEN}>>> Instalando Atuin...${NC}"
    
    if ! command -v atuin &> /dev/null; then
        if [ -f /etc/redhat-release ]; then
            echo -e "${CYAN}   Detectado Fedora: Instalando desde repositorios oficiales...${NC}"
            $SUDO_CMD dnf install -y atuin
        elif [ -f /etc/arch-release ]; then
            echo -e "${CYAN}   Detectado Arch: Instalando desde repositorios oficiales...${NC}"
            $SUDO_CMD pacman -S atuin --noconfirm
        elif [ -f /etc/debian_version ]; then
            echo -e "${CYAN}   Detectado Debian/Ubuntu: Intentando instalación nativa (apt)...${NC}"
            # Intentar apt primero (Ubuntu 24.04+ tiene atuin)
            if ! $SUDO_CMD apt-get install -y atuin 2>/dev/null; then
                 echo -e "${YELLOW}   ! Paquete no encontrado en apt (versión antigua). Usando script oficial...${NC}"
                 curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | bash
            fi
        else
            # Fallback genérico
            echo -e "${CYAN}   Sistema no específico detectado: Usando script oficial...${NC}"
            curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | bash
        fi

        echo -e "${CYAN}   ✓ Atuin instalado${NC}"
    else
        echo -e "${YELLOW}   ! Atuin ya está instalado${NC}"
    fi

    # Configurar .bashrc (Antes de ble-attach)
    BASHRC="$HOME/.bashrc"
    
    # Asegurar que la ruta de atuin esté disponible para el eval
    export PATH="$HOME/.atuin/bin:$PATH"
    
    # Configurar .bashrc (Atuin INIT)
    CONTENT=$(cat <<EOF
# Atuin (Magical Shell History)
if [ -f "\$HOME/.atuin/bin/env" ]; then
    . "\$HOME/.atuin/bin/env"
fi
if command -v atuin &>/dev/null; then
    eval "\$(atuin init bash)"
fi
EOF
)
    sed -i '/atuin init bash/d' "$BASHRC"
    update_bashrc_block "ATUIN" "$CONTENT" "before-ble"
    echo -e "${CYAN}   ✓ Atuin init agregado a .bashrc${NC}"

    # Instrucciones post-instalación
    echo -e "${YELLOW}   ⚠️  Paso final (requiere interacción manual):${NC}"
    echo -e "${YELLOW}   Ejecuta estos comandos para sincronizar tu historial:${NC}"
    echo -e "${CYAN}     1. atuin register -u <usuario> -e <email>${NC}"
    echo -e "${CYAN}     2. atuin import auto${NC}"
    echo -e "${CYAN}     3. atuin sync${NC}"
}

# ─────────────────────────────────────────────────────────────
# Instala Oh My Posh y configura el tema personalizado.
# ─────────────────────────────────────────────────────────────
install_oh_my_posh() {
    echo -e "${GREEN}>>> Instalando Oh My Posh...${NC}"
    
    if ! command -v oh-my-posh &> /dev/null; then
        echo -e "${CYAN}   Descargando e instalando Oh My Posh...${NC}"
        curl -s https://ohmyposh.dev/install.sh | $SUDO_CMD bash -s -- -d /usr/local/bin
        echo -e "${CYAN}   ✓ Oh My Posh instalado${NC}"
    else
        echo -e "${YELLOW}   ! Oh My Posh ya está instalado${NC}"
    fi

    # Configurar tema
    THEME_DIR="$HOME/.cache/oh-my-posh/themes"
    mkdir -p "$THEME_DIR"
    
    if [ -f "$DOTFILES_DIR/config/herwingx.omp.json" ]; then
        echo -e "${CYAN}   Instalando tema herwingx...${NC}"
        ln -sf "$DOTFILES_DIR/config/herwingx.omp.json" "$THEME_DIR/herwingx.omp.json"
    else
        echo -e "${RED}   ✗ No se encontró el tema config/herwingx.omp.json${NC}"
    fi

    # Configurar .bashrc de manera limpia y robusta
    BASHRC="$HOME/.bashrc"
    
    # Bloque de configuración con MARCADORES para fácil reemplazo
    CONTENT=$(cat <<EOF
# Oh My Posh (Prompt Theme)
if command -v oh-my-posh &> /dev/null; then
    if [ -f "$HOME/.cache/oh-my-posh/themes/herwingx.omp.json" ]; then
        eval "\$(oh-my-posh init bash --config ~/.cache/oh-my-posh/themes/herwingx.omp.json)"
    else
        eval "\$(oh-my-posh init bash)"
    fi
fi
EOF
)
    sed -i '/oh-my-posh init bash/d' "$BASHRC"
    update_bashrc_block "OMP" "$CONTENT" "before-ble"
    
    echo -e "${CYAN}   ✓ Tema herwingx configurado en .bashrc${NC}"
}

# ─────────────────────────────────────────────────────────────
# Instalación agrupada de todo el sistema:
# update + packages + git config + ssh keys
# ─────────────────────────────────────────────────────────────
install_system_all() {
    update_system
    install_packages
    install_gitconfig
    install_ssh_keys
    show_reload_message
}

# ─────────────────────────────────────────────────────────────
# Configura el cronjob de actualizaciones automáticas.
# Permite personalizar el horario y frecuencia para evitar conflictos en Proxmox.
#
# Opciones de frecuencia:
# - Diario: Todos los días a la hora configurada
# - Semanal: Cada domingo a la hora configurada
# - Mensual: El día 1 de cada mes a la hora configurada
#
# El cronjob ejecuta cron-update.sh que:
# - Actualiza el sistema (apt/dnf/pacman)
# - Notifica via Telegram
# - Reinicia si hay actualización de kernel
# ─────────────────────────────────────────────────────────────
install_auto_update() {
    echo -e "${GREEN}>>> Configurando actualizaciones automáticas...${NC}"
    
    # Verificar que existan las credenciales de Telegram
    decrypt_secrets
    if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
        echo -e "${RED}   ✗ Credenciales de Telegram no encontradas en .env.age${NC}"
        echo -e "${YELLOW}   Agrega TELEGRAM_BOT_TOKEN y TELEGRAM_CHAT_ID a ~/.env.age${NC}"
        return 1
    fi
    
    # Menú de frecuencia
    echo ""
    echo -e "${CYAN}   ┌──────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}   │${NC}  ${BOLD}Frecuencia de actualizaciones${NC}            ${CYAN}│${NC}"
    echo -e "${CYAN}   ├──────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}   │${NC}   ${GREEN}1)${NC} 📅 Diario (recomendado servidores)    ${CYAN}│${NC}"
    echo -e "${CYAN}   │${NC}   ${GREEN}2)${NC} 📆 Semanal (domingos)                 ${CYAN}│${NC}"
    echo -e "${CYAN}   │${NC}   ${GREEN}3)${NC} 🗓️  Mensual (día 1 de cada mes)        ${CYAN}│${NC}"
    echo -e "${CYAN}   └──────────────────────────────────────────┘${NC}"
    echo ""
    read -p "   Selecciona frecuencia [1-3, default: 1]: " FREQ_OPTION
    FREQ_OPTION=${FREQ_OPTION:-1}
    
    case "$FREQ_OPTION" in
        1)
            CRON_FREQUENCY="daily"
            CRON_DAY_OF_WEEK="*"
            CRON_DAY_OF_MONTH="*"
            FREQ_LABEL="diario"
            ;;
        2)
            CRON_FREQUENCY="weekly"
            CRON_DAY_OF_WEEK="0"  # Domingo
            CRON_DAY_OF_MONTH="*"
            FREQ_LABEL="semanal (domingos)"
            ;;
        3)
            CRON_FREQUENCY="monthly"
            CRON_DAY_OF_WEEK="*"
            CRON_DAY_OF_MONTH="1"  # Día 1
            FREQ_LABEL="mensual (día 1)"
            ;;
        *)
            echo -e "${YELLOW}   ! Opción inválida, usando diario${NC}"
            CRON_FREQUENCY="daily"
            CRON_DAY_OF_WEEK="*"
            CRON_DAY_OF_MONTH="*"
            FREQ_LABEL="diario"
            ;;
    esac
    
    echo -e "${CYAN}   Frecuencia seleccionada: $FREQ_LABEL${NC}"
    
    # Solicitar horario personalizado
    echo ""
    echo -e "${CYAN}   Configuración del horario de actualización:${NC}"
    echo -e "${YELLOW}   (Importante: En Proxmox, usa horarios diferentes para PVE y guests)${NC}"
    echo ""
    
    read -p "   Hora (0-23) [default: 3]: " CRON_HOUR
    CRON_HOUR=${CRON_HOUR:-3}
    
    read -p "   Minuto (0-59) [default: 0]: " CRON_MINUTE
    CRON_MINUTE=${CRON_MINUTE:-0}
    
    # Validar entrada
    if ! [[ "$CRON_HOUR" =~ ^[0-9]+$ ]] || [ "$CRON_HOUR" -gt 23 ]; then
        echo -e "${RED}   ✗ Hora inválida, usando 3${NC}"
        CRON_HOUR=3
    fi
    
    if ! [[ "$CRON_MINUTE" =~ ^[0-9]+$ ]] || [ "$CRON_MINUTE" -gt 59 ]; then
        echo -e "${RED}   ✗ Minuto inválido, usando 0${NC}"
        CRON_MINUTE=0
    fi
    
    echo -e "${CYAN}   Horario configurado: ${CRON_HOUR}:$(printf "%02d" $CRON_MINUTE) $FREQ_LABEL${NC}"
    
    # Copiar script de actualización a /usr/local/bin
    echo -e "${CYAN}   Instalando script de actualización...${NC}"
    $SUDO_CMD cp "$DOTFILES_DIR/scripts/cron-update.sh" /usr/local/bin/dotfiles-update
    $SUDO_CMD chmod +x /usr/local/bin/dotfiles-update
    
    # Crear archivo de configuración con credenciales de Telegram
    echo -e "${CYAN}   Configurando credenciales de Telegram...${NC}"
    $SUDO_CMD tee /etc/dotfiles-telegram.env > /dev/null <<EOF
# Credenciales de Telegram para notificaciones de actualizaciones
# Generado por dotfiles installer
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID
EOF
    $SUDO_CMD chmod 600 /etc/dotfiles-telegram.env
    
    # Configurar cronjob
    echo -e "${CYAN}   Configurando cronjob...${NC}"
    
    # Crear directorio /etc/cron.d/ si no existe (para WSL)
    $SUDO_CMD mkdir -p /etc/cron.d
    
    # Crear archivo cron en /etc/cron.d/
    # Formato cron: minuto hora día_del_mes mes día_de_la_semana
    $SUDO_CMD tee /etc/cron.d/dotfiles-update > /dev/null <<EOF
# Actualizaciones automáticas del sistema - dotfiles
# Frecuencia: $FREQ_LABEL
# Horario: ${CRON_HOUR}:$(printf "%02d" $CRON_MINUTE)
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

$CRON_MINUTE $CRON_HOUR $CRON_DAY_OF_MONTH * $CRON_DAY_OF_WEEK root /usr/local/bin/dotfiles-update >> /var/log/dotfiles-updates.log 2>&1
EOF
    $SUDO_CMD chmod 644 /etc/cron.d/dotfiles-update
    
    # Crear archivo de log si no existe
    $SUDO_CMD touch /var/log/dotfiles-updates.log
    $SUDO_CMD chmod 644 /var/log/dotfiles-updates.log
    
    echo -e "${CYAN}   ✓ Cronjob instalado: ${CRON_HOUR}:$(printf "%02d" $CRON_MINUTE) $FREQ_LABEL${NC}"
    echo -e "${CYAN}   ✓ Script: /usr/local/bin/dotfiles-update${NC}"
    echo -e "${CYAN}   ✓ Log: /var/log/dotfiles-updates.log${NC}"
    echo -e "${CYAN}   ✓ Cron: /etc/cron.d/dotfiles-update${NC}"
    
    # Enviar notificación de prueba
    echo -e "${CYAN}   Enviando notificación de prueba a Telegram...${NC}"
    
    # Usar $HOSTNAME en lugar de $(hostname) para compatibilidad
    CURRENT_HOST="${HOSTNAME:-$(cat /etc/hostname 2>/dev/null || echo 'unknown')}"
    
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="🔧 <b>[$CURRENT_HOST]</b>
Actualizaciones automáticas configuradas.
• Frecuencia: $FREQ_LABEL
• Horario: ${CRON_HOUR}:$(printf "%02d" $CRON_MINUTE)
• Log: /var/log/dotfiles-updates.log" \
        -d parse_mode="HTML" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CYAN}   ✓ Notificación de prueba enviada${NC}"
    else
        echo -e "${YELLOW}   ! No se pudo enviar notificación de prueba${NC}"
    fi
    
    echo -e "${GREEN}>>> Actualizaciones automáticas configuradas${NC}"
}

# ─────────────────────────────────────────────────────────────
# Desinstala el cronjob de actualizaciones automáticas.
# ─────────────────────────────────────────────────────────────
uninstall_auto_update() {
    echo -e "${GREEN}>>> Desinstalando actualizaciones automáticas...${NC}"
    
    $SUDO_CMD rm -f /etc/cron.d/dotfiles-update
    $SUDO_CMD rm -f /usr/local/bin/dotfiles-update
    $SUDO_CMD rm -f /etc/dotfiles-telegram.env
    
    echo -e "${CYAN}   ✓ Cronjob eliminado${NC}"
    echo -e "${YELLOW}   Nota: El log /var/log/dotfiles-updates.log se mantiene${NC}"
}

# ─────────────────────────────────────────────────────────────
# Ejecuta manualmente una actualización (para testing).
# ─────────────────────────────────────────────────────────────
run_manual_update() {
    echo -e "${GREEN}>>> Ejecutando actualización manual...${NC}"
    
    if [ -f /usr/local/bin/dotfiles-update ]; then
        $SUDO_CMD /usr/local/bin/dotfiles-update
    else
        echo -e "${RED}   ✗ Script no instalado. Ejecuta primero la opción de instalar auto-update${NC}"
    fi
}

