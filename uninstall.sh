#!/bin/bash
# ==============================================================================
# DESINSTALADOR INTEGRAL DE DOTFILES
# ==============================================================================
# Elimina configuraciones, enlaces simbólicos y herramientas instaladas.
# Uso: ./uninstall.sh [--all]
# ==============================================================================

source "$(dirname "$0")/scripts/common.sh"

echo -e "${RED}==========================================${NC}"
echo -e "${RED}   ⚠️  PELIGRO: DESINSTALACIÓN DE DOTFILES${NC}"
echo -e "${RED}==========================================${NC}"
echo -e "${YELLOW}Este script eliminará configuraciones de tu usuario.${NC}"
echo ""

# Confirmación
read -p "¿Estás seguro de continuar? (escribe 'si' para confirmar): " CONFIRM
if [ "$CONFIRM" != "si" ]; then
    echo "Cancelado."
    exit 0
fi

echo ""

# 1. Limpiar .bashrc
echo -e "${CYAN}>>> Limpiando .bashrc...${NC}"
sed -i '/oh-my-posh/d' ~/.bashrc
sed -i '/atuin/d' ~/.bashrc
sed -i '/ble.sh/d' ~/.bashrc
sed -i '/ble-attach/d' ~/.bashrc
sed -i '/GITHUB_PERSONAL_ACCESS_TOKEN/d' ~/.bashrc
echo -e "${GREEN}   ✓ .bashrc limpio${NC}"

# 2. Eliminar Enlaces Simbólicos
echo -e "${CYAN}>>> Eliminando enlaces simbólicos...${NC}"
rm -f ~/.bash_aliases
rm -f ~/.gitconfig
rm -f ~/.cache/oh-my-posh/themes/herwingx.omp.json
echo -e "${GREEN}   ✓ Enlaces eliminados${NC}"

# 3. Eliminar Herramientas Locales
echo -e "${CYAN}>>> Eliminando herramientas locales...${NC}"
rm -rf ~/.local/share/blesh
rm -rf ~/.atuin
rm -rf ~/.gemini
rm -f ~/.local/bin/agy

# Revertir parche de Antigravity en WSL (si existe)
if grep -qi microsoft /proc/version 2>/dev/null; then
    echo -e "${CYAN}   >>> Revertiendo configuración de Antigravity (WSL)...${NC}"
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
                echo -e "${GREEN}      ✓ Parche de Windows revertido al original${NC}"
            fi
        fi
    fi
fi

echo -e "${GREEN}   ✓ Carpetas locales y configuraciones eliminadas${NC}"

# 4. Restaurar Backups (si existen)
echo -e "${CYAN}>>> Restaurando backups...${NC}"
if [ -f ~/.bash_aliases.backup ]; then
    mv ~/.bash_aliases.backup ~/.bash_aliases
    echo -e "${GREEN}   ✓ .bash_aliases restaurado${NC}"
fi
if [ -f ~/.gitconfig.backup ]; then
    mv ~/.gitconfig.backup ~/.gitconfig
    echo -e "${GREEN}   ✓ .gitconfig restaurado${NC}"
fi

echo ""
echo -e "${GREEN}✅ Desinstalación completada.${NC}"
echo -e "${YELLOW}Por favor reinicia tu terminal: exec bash${NC}"
