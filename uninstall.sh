#!/bin/bash
# ==============================================================================
# DESINSTALADOR INTEGRAL DE DOTFILES
# ==============================================================================
# Elimina configuraciones, enlaces simbólicos y herramientas instaladas.
# Uso: ./uninstall.sh [--all]
# ==============================================================================

source "$(dirname "$0")/scripts/common.sh"

print_header "FULL SYSTEM REMOVAL"
echo -e "${RED}  ⚠️  DANGER ZONE: You are about to remove your dotfiles config.${NC}"
echo -e "${GRAY}      This will delete local configs, symlinks, and tools.${NC}"
echo ""

# Confirmación
echo -ne "${RED}  >> Are you sure you want to proceed? [yes/NO]: ${NC}"
read CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    print_warning "Uninstall aborted by user."
    exit 0
fi

echo ""

# 1. Limpiar .bashrc
print_header "CLEANING BASH CONFIGURATION"
echo -e "${NEON_CYAN}  >> Removing integration lines from .bashrc...${NC}"
sed -i '/oh-my-posh/d' ~/.bashrc
sed -i '/atuin/d' ~/.bashrc
sed -i '/ble.sh/d' ~/.bashrc
sed -i '/ble-attach/d' ~/.bashrc
sed -i '/GITHUB_PERSONAL_ACCESS_TOKEN/d' ~/.bashrc
print_success ".bashrc cleaned"

# 2. Eliminar Enlaces Simbólicos
echo -e "${NEON_CYAN}  >> Removing symlinks...${NC}"
rm -f ~/.bash_aliases
rm -f ~/.gitconfig
rm -f ~/.cache/oh-my-posh/themes/herwingx.omp.json
print_success "Symlinks removed"

# 3. Eliminar Herramientas Locales
echo -e "${NEON_CYAN}  >> Removing local tools directory...${NC}"
rm -rf ~/.local/share/blesh
rm -rf ~/.atuin
rm -rf ~/.gemini
rm -f ~/.local/bin/agy

# Revertir parche de Antigravity en WSL (si existe)
if grep -qi microsoft /proc/version 2>/dev/null; then
    echo -e "${NEON_CYAN}  >> Reverting Antigravity WSL settings...${NC}"
    # Detectar usuario (método robusto simplificado para uninstall)
    WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tail -n1 | tr -d '\r')
    if [ -z "$WIN_USER" ] && [ -f "/mnt/c/Windows/System32/cmd.exe" ]; then
        WIN_USER=$(/mnt/c/Windows/System32/cmd.exe /c "echo %USERNAME%" 2>/dev/null | tail -n1 | tr -d '\r')
    fi
    
    if [ -n "$WIN_USER" ]; then
        AGY_PATH="/mnt/c/Users/$WIN_USER/AppData/Local/Programs/Antigravity/bin/antigravity"
        if [ -f "$AGY_PATH" ]; then
            if grep -q "WSL_EXT_ID=\"google.antigravity-remote-wsl\"" "$AGY_PATH"; then
                sed -i 's/WSL_EXT_ID="google.antigravity-remote-wsl"/WSL_EXT_ID="ms-vscode-remote.remote-wsl"/' "$AGY_PATH"
                print_success "Windows launcher patched back to original"
            else
                print_info "Launcher usage already standard, no patch needed."
            fi
        fi
    fi
fi

print_success "Local directories removed"

# 4. Restaurar Backups (si existen)
echo -e "${NEON_CYAN}  >> Checking for backups...${NC}"
if [ -f ~/.bash_aliases.backup ]; then
    mv ~/.bash_aliases.backup ~/.bash_aliases
    print_success ".bash_aliases restored from backup"
fi
if [ -f ~/.gitconfig.backup ]; then
    mv ~/.gitconfig.backup ~/.gitconfig
    print_success ".gitconfig restored from backup"
fi

echo ""
print_success "UNINSTALLATION COMPLETE"
echo -e "${GRAY}  Please restart your shell: ${WHITE}exec bash${NC}"
