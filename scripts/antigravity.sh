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
        
        BASHRC="$HOME/.bashrc"
        
        # Limpieza legacy (líneas sueltas sin marcadores)
        sed -i '/export GITHUB_PERSONAL_ACCESS_TOKEN=/d' "$BASHRC"
        sed -i '/# GitHub Token para Gemini CLI/d' "$BASHRC"
        sed -i '/# GitHub Token (Preserved/d' "$BASHRC"
        
        # Usar el helper para insertar el token de forma segura
        TOKEN_CONTENT="# GitHub Token para Gemini CLI
export GITHUB_PERSONAL_ACCESS_TOKEN=\"$GH_TOKEN\""
        
        update_bashrc_block "GH_TOKEN" "$TOKEN_CONTENT" "before-ble"
        
        # Exportar también en la sesión actual para que las extensiones lo usen
        export GITHUB_PERSONAL_ACCESS_TOKEN="$GH_TOKEN"
        
        echo -e "${CYAN}   ✓ Token configurado en ~/.bashrc (antes de ble-attach)${NC}"
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
    # 1. Asegurar que el binario de gemini sea accesible
    if [ -z "$(command -v gemini)" ]; then
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi

    # 2. Obtener la ruta absoluta del binario
    GEMINI_BIN=$(command -v gemini)

    # 3. SI EXISTE EN LINUX: Continuar directo a extensiones
    if [ -n "$GEMINI_BIN" ] && [[ "$GEMINI_BIN" != /mnt/* ]]; then
        echo -e "${GREEN}   ✓ Gemini CLI detectado en $GEMINI_BIN${NC}"
        # Continuar directo a la instalación de extensiones (línea 230+)
        
    # 4. SI EXISTE SOLO EN WINDOWS: Ofrecer instalar versión Linux
    elif [ -n "$GEMINI_BIN" ] && [[ "$GEMINI_BIN" == /mnt/* ]]; then
        echo -e "${YELLOW}   ! Gemini detectado en Windows ($GEMINI_BIN).${NC}"
        echo -e "${YELLOW}   ! WSL no puede ejecutar extensiones MCP desde binarios de Windows.${NC}"
        
        # Verificar si npm está disponible en WSL
        if command -v npm &> /dev/null; then
            INSTALL_GEMINI="S"
            
            # Preguntar solo si NO es modo automático
            if [ "$AUTO_INSTALL" != "true" ]; then
                echo -e "${CYAN}   ¿Instalar Gemini CLI dentro de WSL ahora? (recomendado)${NC}"
                read -p "   [S/n]: " INSTALL_GEMINI
                INSTALL_GEMINI=${INSTALL_GEMINI:-S}
            else
                echo -e "${CYAN}   [Modo automático] Instalando Gemini CLI en WSL...${NC}"
            fi
            
            if [[ "$INSTALL_GEMINI" =~ ^[Ss]$ ]]; then
                npm install -g @google/gemini-cli
                
                # Recargar NVM para detectar el nuevo binario
                export NVM_DIR="$HOME/.nvm"
                [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
                
                GEMINI_BIN=$(command -v gemini)
                
                if [ -n "$GEMINI_BIN" ] && [[ "$GEMINI_BIN" != /mnt/* ]]; then
                    echo -e "${GREEN}   ✓ Gemini CLI instalado correctamente en $GEMINI_BIN${NC}"
                else
                    echo -e "${RED}   ✗ Error: Gemini no se instaló correctamente${NC}"
                    return
                fi
            else
                echo -e "${YELLOW}   Saltando instalación de extensiones MCP${NC}"
                return
            fi
        else
            echo -e "${RED}   ! npm no encontrado. Instala Node.js primero (opción 11)${NC}"
            return
        fi
        
    # 5. SI NO EXISTE: Ofrecer instalación solo si viene de opción 20 (Settings)
    else
        echo -e "${YELLOW}   ! Gemini CLI no encontrado.${NC}"
        
        # Si viene de "install_all" (opción 1), dev-tools.sh ya lo instaló o lo hará
        # Solo ofrecer instalación manual si viene de opción 20 (Settings individual)
        if [ "$AUTO_INSTALL" = "true" ]; then
            echo -e "${YELLOW}   Gemini CLI se instalará con Dev Tools (opción 3)${NC}"
            echo -e "${YELLOW}   Saltando extensiones por ahora. Ejecuta opción 20 después.${NC}"
            return
        fi
        
        # Ofrecer instalación si npm está disponible y es opción 20
        if command -v npm &> /dev/null; then
            echo -e "${CYAN}   ¿Instalar Gemini CLI ahora?${NC}"
            read -p "   [S/n]: " INSTALL_GEMINI
            INSTALL_GEMINI=${INSTALL_GEMINI:-S}
            
            if [[ "$INSTALL_GEMINI" =~ ^[Ss]$ ]]; then
                npm install -g @google/gemini-cli
                
                # Recargar NVM
                export NVM_DIR="$HOME/.nvm"
                [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
                
                GEMINI_BIN=$(command -v gemini)
                
                if [ -n "$GEMINI_BIN" ]; then
                    echo -e "${GREEN}   ✓ Gemini CLI instalado correctamente${NC}"
                else
                    echo -e "${RED}   ✗ Error instalando Gemini CLI${NC}"
                    return
                fi
            else
                echo -e "${YELLOW}   Saltando extensiones MCP${NC}"
                return
            fi
        else
            echo -e "${YELLOW}   Instala Node.js primero (opción 11) y npm packages (opción 12)${NC}"
            return
        fi
    fi
    
    # 4. Verificar versión con un timeout más generoso para WSL
    echo -e "${CYAN}   Detectando versión de Gemini en $GEMINI_BIN...${NC}"
    GEMINI_VERSION=$(timeout 20s "$GEMINI_BIN" --version 2>/dev/null || echo "undetected")
    echo -e "${GREEN}>>> Procesando extensiones MCP en Gemini ($GEMINI_VERSION)...${NC}"
    
    declare -a extensions=(
        "https://github.com/ChromeDevTools/chrome-devtools-mcp"
        "https://github.com/github/github-mcp-server"
        "https://github.com/gemini-cli-extensions/postgres"
        "https://github.com/gemini-cli-extensions/nanobanana"
    )

    for ext in "${extensions[@]}"; do
        echo -e "${CYAN}   Instalando: $ext...${NC}"
        LOG_FILE=$(mktemp)
        
        # 4. Usar el binario absoluto y enviar 'yes' de forma robusta
        # En WSL, a veces 'bash -c' pierde el entorno si no se exporta todo.
        # Ejecutar directamente con la ruta absoluta del binario detectado.
        if timeout 120s bash -c "yes | \"$GEMINI_BIN\" extensions install \"$ext\"" > "$LOG_FILE" 2>&1; then
             echo -e "${CYAN}   ✓ Instalada: $ext${NC}"
        else
             # Comprobar si el error es porque ya está instalada
             if grep -qE "already installed|already registered" "$LOG_FILE"; then
                 echo -e "${YELLOW}   ! La extensión ya estaba registrada (Saltando...)${NC}"
             else
                 echo -e "${RED}   ✗ Error instalando $ext${NC}"
                 echo -e "${YELLOW}     Detalles del error:${NC}"
                 if [ -s "$LOG_FILE" ]; then
                     cat "$LOG_FILE" | sed 's/^/     /'
                 else
                     echo -e "     (Sin salida del comando - Posible timeout o error de shell)"
                 fi
             fi
        fi
        rm -f "$LOG_FILE"
    done
    
    echo -e "${CYAN}   Verificando actualizaciones de extensiones...${NC}"
    if timeout 60s "$GEMINI_BIN" extensions update --all &>/dev/null; then
        echo -e "${CYAN}   ✓ Todas las extensiones están actualizadas${NC}"
    else
        echo -e "${YELLOW}   ! Hubo un problema actualizando extensiones (no crítico)${NC}"
    fi

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
