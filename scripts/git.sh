#!/bin/bash
# ==========================================
# GIT - Configuración de Git y SSH
# ==========================================
# Funciones para configurar git y manejar llaves SSH.
# Incluye importación de llaves desde GitHub y copia desde Windows.
# ==========================================

# ─────────────────────────────────────────────────────────────
# Configura Git
#
# Copia el .gitconfig base al home del usuario y fuerza que
# toda conexión a GitHub se realice por SSH, lo cual es vital
# para habilitar SSH Agent Forwarding.
#
# @sideeffects Sobrescribe `~/.gitconfig`.
# ─────────────────────────────────────────────────────────────
install_gitconfig() {
    print_step "Configurando Git..."
    cp "$DOTFILES_DIR/config/.gitconfig" "$HOME/.gitconfig"
    # Fuerza SSH aunque copies links HTTPS (vital para forwarding)
    git config --global url."git@github.com:".insteadOf "https://github.com/"
    print_success "Git configurado"

    # Configurar credential helper para persistencia en LXC/Headless
    # En WSL git suele usar el de Windows, pero en LXC puro necesitamos 'store' o 'cache'
    if ! grep -qi microsoft /proc/version 2>/dev/null; then
         # Si no es WSL (es un Linux nativo o container)
         print_info "Configurando credential.helper store (para persistencia en LXC)..."
         git config --global credential.helper store
    fi
}

# ─────────────────────────────────────────────────────────────
# Importa llaves públicas SSH
#
# Descarga las llaves públicas registradas del autor desde GitHub
# y las añade a `authorized_keys` para permitir acceso seguro remoto.
#
# @sideeffects Modifica/crea `~/.ssh/authorized_keys`.
# ─────────────────────────────────────────────────────────────
install_ssh_keys() {
    print_step "Importando llaves públicas de herwingx..."
    mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    curl -s "https://github.com/herwingx.keys" >> "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys"
    print_success "Llaves SSH importadas"
}

# ─────────────────────────────────────────────────────────────
# Importa llaves SSH desde Windows (Solo WSL)
#
# Busca en la ruta `C:\Users\...\.ssh` las llaves privadas (RSA,
# Ed25519) y las copia al entorno Linux asegurando permisos
# correctos (600/700).
#
# @sideeffects Copia archivos a `~/.ssh/`.
# ─────────────────────────────────────────────────────────────
copy_ssh_from_windows() {
    print_step "Copiando llaves SSH desde Windows a WSL..."
    
    if [ ! -d "/mnt/c" ]; then
        print_error "No se detectó WSL. Esta opción solo funciona en WSL."
        return 1
    fi
    
    # Detectar usuario de Windows
    if [ -n "$WSLENV" ] || [ -f "/proc/sys/fs/binfmt_misc/WSLInterop" ]; then
        WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
        
        if [ -z "$WIN_USER" ] || [ "$WIN_USER" = "%USERNAME%" ]; then
            WIN_USER=$(ls -td /mnt/c/Users/*/ 2>/dev/null | grep -v -E "(Public|Default|All Users)" | head -1 | xargs basename)
        fi
    fi
    
    if [ -z "$WIN_USER" ]; then
        print_warning "No se pudo detectar el usuario de Windows."
        read -p "   Ingresa tu nombre de usuario de Windows: " WIN_USER
    fi
    
    WIN_SSH_DIR="/mnt/c/Users/$WIN_USER/.ssh"
    
    if [ ! -d "$WIN_SSH_DIR" ]; then
        print_error "No se encontró: $WIN_SSH_DIR"
        return 1
    fi
    
    print_info "Usuario de Windows: $WIN_USER"
    print_info "Copiando desde: $WIN_SSH_DIR"
    
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    
    KEYS_COPIED=0
    for key_type in id_rsa id_ed25519 id_ecdsa; do
        if [ -f "$WIN_SSH_DIR/$key_type" ]; then
            cp "$WIN_SSH_DIR/$key_type" "$HOME/.ssh/"
            chmod 600 "$HOME/.ssh/$key_type"
            print_success "Copiada: $key_type"
            KEYS_COPIED=$((KEYS_COPIED + 1))
        fi
        if [ -f "$WIN_SSH_DIR/$key_type.pub" ]; then
            cp "$WIN_SSH_DIR/$key_type.pub" "$HOME/.ssh/"
            chmod 644 "$HOME/.ssh/$key_type.pub"
        fi
    done
    
    [ -f "$WIN_SSH_DIR/config" ] && cp "$WIN_SSH_DIR/config" "$HOME/.ssh/" && chmod 600 "$HOME/.ssh/config"
    [ -f "$WIN_SSH_DIR/known_hosts" ] && cp "$WIN_SSH_DIR/known_hosts" "$HOME/.ssh/" && chmod 600 "$HOME/.ssh/known_hosts"
    
    if [ $KEYS_COPIED -eq 0 ]; then
        print_warning "No se encontraron llaves SSH."
        return 1
    fi
    
    print_success "$KEYS_COPIED llave(s) copiada(s)"
    print_info "Probando conexión a GitHub..."
    ssh -T git@github.com 2>&1 | head -2
}

# ─────────────────────────────────────────────────────────────
# Configura SSH Agent persistente
#
# Agrega un bloque a `.bashrc` para que inicie `ssh-agent`
# automáticamente si no está corriendo, y cargue las llaves por defecto.
#
# @sideeffects Actualiza `~/.bashrc`.
# ─────────────────────────────────────────────────────────────
configure_ssh_agent() {
    print_step "Configurando SSH Agent auto-start..."
    
    BASHRC="$HOME/.bashrc"
    
    # Bloque de SSH Agent para Linux/WSL
    SSH_AGENT_BLOCK='# SSH Agent - Inicio automático
# Inicia ssh-agent si no está corriendo y agrega la llave por defecto
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null 2>&1
fi

# Agregar llave si existe y no está cargada
if [ -f "$HOME/.ssh/id_ed25519" ]; then
    ssh-add -l 2>/dev/null | grep -q "id_ed25519" || ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null
elif [ -f "$HOME/.ssh/id_rsa" ]; then
    ssh-add -l 2>/dev/null | grep -q "id_rsa" || ssh-add "$HOME/.ssh/id_rsa" 2>/dev/null
fi'

    update_bashrc_block "SSH_AGENT" "$SSH_AGENT_BLOCK" "bottom"
    print_success "SSH Agent configurado en .bashrc"
    
    print_warning "Recarga tu shell (source ~/.bashrc) para activar"
}
