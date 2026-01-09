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
echo -e "${GREEN}   ✓ Carpetas locales eliminadas (~/.local/share/blesh, ~/.atuin, ~/.gemini)${NC}"

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
