#!/bin/bash
# ==============================================================================
# DESINSTALADOR INTEGRAL DE DOTFILES (AGGRESSIVE MODE)
# ==============================================================================

source "$(dirname "$0")/scripts/common.sh"

print_header "FULL SYSTEM REMOVAL"
echo -e "${RED}  ⚠️  DANGER ZONE: You are about to DESTROY your development environment.${NC}"
echo -e "${GRAY}      This action is irreversible and will remove:${NC}"
echo -e "${RED}      - All Dotfiles (.bashrc patches, aliases, gitconfig)${NC}"
echo -e "${RED}      - All Configs (~/.config/nvim, tmux, gemini, etc)${NC}"
echo -e "${RED}      - All Runtimes (NVM/Node, Rust/Cargo, Go, Brew)${NC}"
echo -e "${RED}      - Local Binaries (~/.local/bin)${NC}"
echo -e "${RED}      - Docker (Images, Containers, Volumes) [OPTIONAL]${NC}"
echo ""

# Confirmación Global
echo -ne "${RED}  >> Are you sure you want to proceed? [type 'destroy']: ${NC}"
read CONFIRM
if [ "$CONFIRM" != "destroy" ]; then
    print_warning "Uninstall aborted. You safe."
    exit 0
fi

echo ""

# 1. Limpiar .bashrc (Deep Clean)
print_header "1. CLEANING SHELL CONFIGURATION"
echo -e "${NEON_CYAN}  >> Removing integration lines from .bashrc...${NC}"
# Remove blocks
sed -i '/# MANAGED BY DOTFILES/,/# END MANAGED BY DOTFILES/d' ~/.bashrc 2>/dev/null
# Remove legacy lines
sed -i '/oh-my-posh/d' ~/.bashrc
sed -i '/atuin/d' ~/.bashrc
sed -i '/ble.sh/d' ~/.bashrc
sed -i '/ble-attach/d' ~/.bashrc
sed -i '/nvm/d' ~/.bashrc
sed -i '/NVM_DIR/d' ~/.bashrc
sed -i '/GITHUB_PERSONAL_ACCESS_TOKEN/d' ~/.bashrc
sed -i '/zoxide/d' ~/.bashrc
print_success ".bashrc cleaned"

# 2. Restaurar Backups (si existen)
echo -e "${NEON_CYAN}  >> Restoring backups...${NC}"
[ -f ~/.bashrc.backup ] && mv ~/.bashrc.backup ~/.bashrc && print_success ".bashrc restored"
[ -f ~/.bash_aliases.backup ] && mv ~/.bash_aliases.backup ~/.bash_aliases && print_success ".bash_aliases restored"
[ -f ~/.gitconfig.backup ] && mv ~/.gitconfig.backup ~/.gitconfig && print_success ".gitconfig restored"

# 3. Eliminar Enlaces Simbólicos y Archivos
print_header "2. REMOVING DOTFILES"
rm -f ~/.bash_aliases
rm -f ~/.gitconfig
rm -f ~/.tmux.conf
rm -f ~/.inputrc
rm -rf ~/.gemini
rm -f ~/.local/bin/agy
print_success "Symlinks removed"

# 4. Eliminar Herramientas y Runtimes
print_header "3. REMOVING RUNTIMES & TOOLS"

# NVM / Node
if [ -d "$HOME/.nvm" ]; then
    echo -e "${YELLOW}  >> Removing NVM and Node.js...${NC}"
    rm -rf "$HOME/.nvm"
    rm -rf "$HOME/.npm"
    rm -rf "$HOME/.node_repl_history"
    print_success "NVM removed"
fi

# Rust / Cargo
if [ -d "$HOME/.cargo" ]; then
    echo -e "${YELLOW}  >> Removing Rust (Cargo)...${NC}"
    rm -rf "$HOME/.cargo"
    rm -rf "$HOME/.rustup"
    print_success "Rust removed"
fi

# Local Binaries
echo -e "${YELLOW}  >> Removing local binaries (oh-my-posh, zoxide, etc)...${NC}"
rm -f ~/.local/bin/oh-my-posh
rm -f ~/.local/bin/zoxide
rm -f ~/.local/bin/lsd
rm -rf ~/.local/share/blesh
rm -rf ~/.atuin
rm -rf ~/.cache/oh-my-posh
print_success "Local tools removed"

# Brew (Linuxbrew)
if [ -d "/home/linuxbrew" ]; then
    echo -e "${YELLOW}  >> Detecting Homebrew...${NC}"
    echo -ne "${RED}     Remove Homebrew? [y/N]: ${NC}"
    read RM_BREW
    if [[ "$RM_BREW" =~ ^[Yy]$ ]]; then
         /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
         rm -rf /home/linuxbrew
         print_success "Homebrew removed"
    fi
fi

# 5. Docker Cleanup (Optional)
print_header "4. DOCKER CLEANUP"
if command -v docker &> /dev/null; then
    echo -e "${RED}  ⚠️  DOCKER DETECTED${NC}"
    echo -ne "${RED}     Do you want to PURGE Docker (Images, Containers, Volumes)? [y/N]: ${NC}"
    read RM_DOCKER
    if [[ "$RM_DOCKER" =~ ^[Yy]$ ]]; then
        echo -e "${NEON_CYAN}     Stopping containers...${NC}"
        docker stop $(docker ps -aq) 2>/dev/null
        docker rm $(docker ps -aq) 2>/dev/null
        
        echo -e "${NEON_CYAN}     Removing everything...${NC}"
        docker system prune -a --volumes -f
        
        # Desinstalar paquetes sistema
        if [ -f /etc/debian_version ]; then
            sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        elif [ -f /etc/redhat-release ]; then
            sudo dnf remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        fi
        
        # Eliminar grupos
        sudo groupdel docker 2>/dev/null
        
        print_success "Docker PURGED"
    else
        print_info "Docker skipped"
    fi
fi

print_header "CLEANUP COMPLETE"
echo -e "${GRAY}  Environment reset to stock. Please restart your shell.${NC}"
echo -e "${WHITE}  exec bash${NC}"
