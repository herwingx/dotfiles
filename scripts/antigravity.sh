#!/bin/bash
# ==========================================
# ANTIGRAVITY - Reglas y Workflows de IA
# ==========================================
# Funciones para instalar configuración de Antigravity/Gemini:
# - GEMINI.md: Reglas globales de desarrollo
# - Workflows: Comandos slash (/commit, /publicar, etc.)
# ==========================================

# ─────────────────────────────────────────────────────────────
# Instala las reglas de Antigravity (GEMINI.md).
# Copia desde gemini/GEMINI.md a ~/.gemini/GEMINI.md
# Crea backup si existe un archivo previo.
# ─────────────────────────────────────────────────────────────
install_antigravity_rules() {
    echo -e "${GREEN}>>> Configurando Antigravity - Reglas (GEMINI.md)...${NC}"
    GEMINI_DIR="$HOME/.gemini"
    
    if [ ! -d "$GEMINI_DIR" ]; then
        echo -e "${YELLOW}   ! Directorio ~/.gemini no existe. Creándolo...${NC}"
        mkdir -p "$GEMINI_DIR"
    fi
    
    if [ -f "$GEMINI_DIR/GEMINI.md" ]; then
        echo -e "${YELLOW}   ! GEMINI.md existente. Creando backup...${NC}"
        mv "$GEMINI_DIR/GEMINI.md" "$GEMINI_DIR/GEMINI.md.backup"
    fi
    
    cp "$DOTFILES_DIR/gemini/GEMINI.md" "$GEMINI_DIR/GEMINI.md"
    echo -e "${CYAN}   ✓ Reglas instaladas en $GEMINI_DIR${NC}"
}

# ─────────────────────────────────────────────────────────────
# Instala los workflows de Antigravity.
# Copia desde gemini/workflows/ a ~/.gemini/antigravity/global_workflows/
# Lista los workflows disponibles tras la instalación.
# ─────────────────────────────────────────────────────────────
install_antigravity_workflows() {
    echo -e "${GREEN}>>> Configurando Antigravity - Workflows...${NC}"
    WORKFLOWS_DIR="$HOME/.gemini/antigravity/global_workflows"
    
    if [ ! -d "$WORKFLOWS_DIR" ]; then
        echo -e "${YELLOW}   ! Directorio de workflows no existe. Creándolo...${NC}"
        mkdir -p "$WORKFLOWS_DIR"
    fi
    
    if [ -d "$DOTFILES_DIR/gemini/workflows" ]; then
        cp -r "$DOTFILES_DIR/gemini/workflows/"* "$WORKFLOWS_DIR/"
        echo -e "${CYAN}   ✓ Workflows instalados en $WORKFLOWS_DIR${NC}"
        echo -e "${CYAN}   Workflows disponibles:${NC}"
        ls -1 "$WORKFLOWS_DIR" | while read workflow; do
            echo -e "${CYAN}     - /${workflow%.md}${NC}"
        done
    else
        echo -e "${RED}   ✗ No se encontró gemini/workflows en dotfiles${NC}"
    fi
}

# ─────────────────────────────────────────────────────────────
# Instalación completa de Antigravity: reglas + workflows.
# ─────────────────────────────────────────────────────────────
install_antigravity_full() {
    install_antigravity_rules
    install_antigravity_workflows
}
