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
# Instala la configuración de Gemini (settings.json).
# Configura el token de GitHub para el servidor MCP.
# ─────────────────────────────────────────────────────────────
install_gemini_settings() {
    echo -e "${GREEN}>>> Configurando Antigravity - Settings (settings.json)...${NC}"
    GEMINI_DIR="$HOME/.gemini"
    
    # Cargar secrets si no están disponibles
    if [ -z "$GH_TOKEN" ]; then
        decrypt_secrets 2>/dev/null || true
    fi
    
    if [ ! -d "$GEMINI_DIR" ]; then
        mkdir -p "$GEMINI_DIR"
    fi

    # Copiar el template si no existe o actualizar
    cp "$DOTFILES_DIR/gemini/settings.json" "$GEMINI_DIR/settings.json"
    
    # Intentar obtener el token (asumiendo que GH_TOKEN está disponible vía decrypt_secrets o env)
    # Si no está, se deja el placeholder ${GITHUB_PERSONAL_ACCESS_TOKEN}
    if [ -n "$GH_TOKEN" ]; then
        echo -e "${CYAN}   Token detectado. Configurando persistencia en ~/.bashrc...${NC}"
        
        # Eliminar entrada anterior si existe para evitar duplicados
        sed -i '/export GITHUB_PERSONAL_ACCESS_TOKEN=/d' ~/.bashrc
        
        # Añadir nueva entrada
        echo "export GITHUB_PERSONAL_ACCESS_TOKEN=\"$GH_TOKEN\"" >> ~/.bashrc
        echo -e "${CYAN}   ✓ Token configurado en ~/.bashrc${NC}"
    else
        echo -e "${YELLOW}   ! No se detectó GH_TOKEN. Recuerda configurarlo manualmente o vía Bitwarden.${NC}"
    fi

    echo -e "${CYAN}   ✓ Settings instalados en $GEMINI_DIR${NC}"
    
    # Instalar extensiones MCP
    install_gemini_extensions
}

# ─────────────────────────────────────────────────────────────
# Instala extensiones MCP para Gemini CLI.
# ─────────────────────────────────────────────────────────────
install_gemini_extensions() {
    if ! command -v gemini &> /dev/null; then
        echo -e "${YELLOW}   ! Gemini CLI no detectado. Saltando instalación de extensiones.${NC}"
        echo -e "${YELLOW}     (Asegúrate de tener instalado @google/gemini-cli o equivalente)${NC}"
        return
    fi

    echo -e "${GREEN}>>> Instalando extensiones MCP en Gemini...${NC}"
    
    declare -a extensions=(
        "https://github.com/ChromeDevTools/chrome-devtools-mcp"
        "https://github.com/github/github-mcp-server"
        "https://github.com/gemini-cli-extensions/postgres"
        "https://github.com/gemini-cli-extensions/nanobanana"
    )

    for ext in "${extensions[@]}"; do
        echo -e "${CYAN}   Instalando: $ext...${NC}"
        gemini extensions install "$ext" || echo -e "${RED}   ✗ Error instalando $ext (posiblemente ya instalada)${NC}"
    done
    
    echo -e "${CYAN}   ✓ Extensiones procesadas${NC}"
}

# ─────────────────────────────────────────────────────────────
# Instalación completa de Antigravity: reglas + workflows + settings.
# ─────────────────────────────────────────────────────────────
install_antigravity_full() {
    install_antigravity_rules
    install_antigravity_workflows
    install_gemini_settings
}
