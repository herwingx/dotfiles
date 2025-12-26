#!/bin/bash
# ==========================================
# GIT - Configuración de Git y SSH
# ==========================================
# Funciones para configurar git y manejar llaves SSH.
# Incluye importación de llaves desde GitHub y copia desde Windows.
# ==========================================

# ─────────────────────────────────────────────────────────────
# Copia el .gitconfig desde config/ al home del usuario.
# Configura git para usar SSH en lugar de HTTPS para GitHub.
# Esto es vital para que funcione el SSH Agent Forwarding.
# ─────────────────────────────────────────────────────────────
install_gitconfig() {
    echo -e "${GREEN}>>> Configurando Git...${NC}"
    cp "$DOTFILES_DIR/config/.gitconfig" "$HOME/.gitconfig"
    # Fuerza SSH aunque copies links HTTPS (vital para forwarding)
    git config --global url."git@github.com:".insteadOf "https://github.com/"
    echo -e "${CYAN}   ✓ Git configurado${NC}"
}

# ─────────────────────────────────────────────────────────────
# Importa las llaves públicas de herwingx desde GitHub.
# Las agrega a ~/.ssh/authorized_keys para acceso SSH.
# ─────────────────────────────────────────────────────────────
install_ssh_keys() {
    echo -e "${GREEN}>>> Importando llaves públicas de herwingx...${NC}"
    mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    curl -s "https://github.com/herwingx.keys" >> "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys"
    echo -e "${CYAN}   ✓ Llaves SSH importadas${NC}"
}

# ─────────────────────────────────────────────────────────────
# Copia llaves SSH desde Windows a WSL.
# Solo funciona en Windows Subsystem for Linux.
# Detecta automáticamente el usuario de Windows.
# ─────────────────────────────────────────────────────────────
copy_ssh_from_windows() {
    echo -e "${GREEN}>>> Copiando llaves SSH desde Windows a WSL...${NC}"
    
    if [ ! -d "/mnt/c" ]; then
        echo -e "${RED}   ✗ No se detectó WSL. Esta opción solo funciona en WSL.${NC}"
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
        echo -e "${YELLOW}   ! No se pudo detectar el usuario de Windows.${NC}"
        read -p "   Ingresa tu nombre de usuario de Windows: " WIN_USER
    fi
    
    WIN_SSH_DIR="/mnt/c/Users/$WIN_USER/.ssh"
    
    if [ ! -d "$WIN_SSH_DIR" ]; then
        echo -e "${RED}   ✗ No se encontró: $WIN_SSH_DIR${NC}"
        return 1
    fi
    
    echo -e "${CYAN}   Usuario de Windows: $WIN_USER${NC}"
    echo -e "${CYAN}   Copiando desde: $WIN_SSH_DIR${NC}"
    
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    
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
    
    [ -f "$WIN_SSH_DIR/config" ] && cp "$WIN_SSH_DIR/config" "$HOME/.ssh/" && chmod 600 "$HOME/.ssh/config"
    [ -f "$WIN_SSH_DIR/known_hosts" ] && cp "$WIN_SSH_DIR/known_hosts" "$HOME/.ssh/" && chmod 600 "$HOME/.ssh/known_hosts"
    
    if [ $KEYS_COPIED -eq 0 ]; then
        echo -e "${YELLOW}   ! No se encontraron llaves SSH.${NC}"
        return 1
    fi
    
    echo -e "${CYAN}   ✓ $KEYS_COPIED llave(s) copiada(s)${NC}"
    echo -e "${CYAN}   Probando conexión a GitHub...${NC}"
    ssh -T git@github.com 2>&1 | head -2
}
