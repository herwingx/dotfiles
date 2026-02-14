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
    print_step "Configurando Antigravity - Reglas (GEMINI.md)..."
    GEMINI_DIR="$HOME/.gemini"
    
    if [ ! -d "$GEMINI_DIR" ]; then
        print_info "Directorio ~/.gemini no existe. Creándolo..."
        mkdir -p "$GEMINI_DIR"
    fi
    
    if [ -f "$GEMINI_DIR/GEMINI.md" ]; then
        print_warning "GEMINI.md existente. Creando backup..."
        mv "$GEMINI_DIR/GEMINI.md" "$GEMINI_DIR/GEMINI.md.backup"
    fi
    
    cp "$DOTFILES_DIR/gemini/GEMINI.md" "$GEMINI_DIR/GEMINI.md"
    print_success "Reglas instaladas en $GEMINI_DIR"
}

# ─────────────────────────────────────────────────────────────
# Instala los workflows de Antigravity.
# Copia desde gemini/workflows/ a ~/.gemini/antigravity/global_workflows/
# Lista los workflows disponibles tras la instalación.
# ─────────────────────────────────────────────────────────────
install_antigravity_workflows() {
    print_step "Configurando Antigravity - Workflows..."
    WORKFLOWS_DIR="$HOME/.gemini/antigravity/global_workflows"
    
    if [ ! -d "$WORKFLOWS_DIR" ]; then
        print_info "Directorio de workflows no existe. Creándolo..."
        mkdir -p "$WORKFLOWS_DIR"
    fi
    
    if [ -d "$DOTFILES_DIR/gemini/workflows" ]; then
        cp -r "$DOTFILES_DIR/gemini/workflows/"* "$WORKFLOWS_DIR/"
        print_success "Workflows instalados en $WORKFLOWS_DIR"
        echo -e "${CYAN}   Workflows disponibles:${NC}"
        ls -1 "$WORKFLOWS_DIR" | while read workflow; do
            echo -e "${CYAN}     - /${workflow%.md}${NC}"
        done
    else
        print_error "No se encontró gemini/workflows en dotfiles"
    fi
}

# ─────────────────────────────────────────────────────────────
# Instala la configuración de Gemini (settings.json).
# Configura el token de GitHub para el servidor MCP.
# ─────────────────────────────────────────────────────────────
install_gemini_settings() {
    print_step "Configurando Antigravity - Settings (settings.json)..."
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
    if [ -n "$GH_TOKEN" ]; then
        print_info "Token detectado. Configurando persistencia en ~/.bashrc..."
        
        BASHRC="$HOME/.bashrc"
        
        # Limpieza legacy
        sed -i '/export GITHUB_PERSONAL_ACCESS_TOKEN=/d' "$BASHRC"
        sed -i '/# GitHub Token para Gemini CLI/d' "$BASHRC"
        sed -i '/# GitHub Token (Preserved/d' "$BASHRC"
        
        # Usar el helper para insertar el token de forma segura
        TOKEN_CONTENT="# GitHub Token para Gemini CLI
export GITHUB_PERSONAL_ACCESS_TOKEN=\"$GH_TOKEN\""
        
        update_bashrc_block "GH_TOKEN" "$TOKEN_CONTENT" "before-ble"
        
        # Exportar también en la sesión actual para que las extensiones lo usen
        export GITHUB_PERSONAL_ACCESS_TOKEN="$GH_TOKEN"
        
        print_success "Token configurado en ~/.bashrc (antes de ble-attach)"
    else
        print_warning "No se detectó GH_TOKEN. Recuerda configurarlo manualmente o vía Bitwarden."
    fi

    print_success "Settings instalados en $GEMINI_DIR"
    
    # Instalar extensiones MCP
    install_gemini_extensions
}

# ─────────────────────────────────────────────────────────────
# Instala extensiones MCP para Gemini CLI.
# ─────────────────────────────────────────────────────────────
install_gemini_extensions() {
    # 0. Limpiar extensiones rotas preventivamente
    if [ -d "$HOME/.gemini/extensions" ]; then
        # Usar find para evitar problemas con globs y ser más precisos
        find "$HOME/.gemini/extensions" -maxdepth 1 -type d -not -path "$HOME/.gemini/extensions" | while read -r ext_dir; do
            if [ ! -f "$ext_dir/gemini-extension.json" ]; then
                print_warning "Detectada extensión corrupta en $(basename "$ext_dir"). Limpiando..."
                rm -rf "$ext_dir"
            fi
        done
    fi

    # 1. Asegurar que el binario de gemini sea accesible
    if [ -z "$(command -v gemini)" ]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi

    # 2. Obtener la ruta absoluta del binario
    GEMINI_BIN=$(command -v gemini)

    # 3. Exportar token para evitar prompts de login interactivo
    if [ -n "$GH_TOKEN" ]; then
        export GITHUB_PERSONAL_ACCESS_TOKEN="$GH_TOKEN"
    fi

    if [ -z "$GITHUB_PERSONAL_ACCESS_TOKEN" ] && [ -z "$GH_TOKEN" ]; then
        print_warning "No se detectó GITHUB_TOKEN. Saltando instalación de extensiones para evitar bloqueos."
        print_info "Configura tus secretos (Opción 7) para habilitar esta funcionalidad."
        return
    fi

    # 4. SI EXISTE EN LINUX: Continuar directo a extensiones
    if [ -n "$GEMINI_BIN" ] && [[ "$GEMINI_BIN" != /mnt/* ]]; then
        print_success "Gemini CLI detectado en $GEMINI_BIN"
        
    # 4. SI EXISTE SOLO EN WINDOWS: Ofrecer instalar versión Linux
    elif [ -n "$GEMINI_BIN" ] && [[ "$GEMINI_BIN" == /mnt/* ]]; then
        print_warning "Gemini detectado en Windows ($GEMINI_BIN)."
        print_warning "WSL no puede ejecutar extensiones MCP desde binarios de Windows."
        
        # Verificar si npm está disponible en WSL
        if command -v npm &> /dev/null; then
            INSTALL_GEMINI="S"
            
            # Preguntar solo si NO es modo automático
            if [ "$AUTO_INSTALL" != "true" ]; then
                echo -e "${CYAN}   ¿Instalar Gemini CLI dentro de WSL ahora? (recomendado)${NC}"
                read -p "   [S/n]: " INSTALL_GEMINI
                INSTALL_GEMINI=${INSTALL_GEMINI:-S}
            else
                print_info "[Modo automático] Instalando Gemini CLI en WSL..."
            fi
            
            if [[ "$INSTALL_GEMINI" =~ ^[Ss]$ ]]; then
                npm install -g @google/gemini-cli
                
                # Recargar NVM para detectar el nuevo binario
                export NVM_DIR="$HOME/.nvm"
                [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
                
                GEMINI_BIN=$(command -v gemini)
                
                if [ -n "$GEMINI_BIN" ] && [[ "$GEMINI_BIN" != /mnt/* ]]; then
                    print_success "Gemini CLI instalado correctamente en $GEMINI_BIN"
                else
                    print_error "Error: Gemini no se instaló correctamente"
                    return
                fi
            else
                print_warning "Saltando instalación de extensiones MCP"
                return
            fi
        else
            print_error "npm no encontrado. Instala Node.js primero (opción 11)"
            return
        fi
        
    # 5. SI NO EXISTE: Ofrecer instalación
    else
        print_warning "Gemini CLI no encontrado."
        
        # Si viene de "install_all" (opción 1), dev-tools.sh ya lo instaló o lo hará
        if [ "$AUTO_INSTALL" = "true" ]; then
            print_info "Gemini CLI se instalará con Dev Tools (opción 3)"
            print_info "Saltando extensiones por ahora. Ejecuta opción 20 después."
            return
        fi
        
        if command -v npm &> /dev/null; then
            echo -e "${CYAN}   ¿Instalar Gemini CLI ahora?${NC}"
            read -p "   [S/n]: " INSTALL_GEMINI
            INSTALL_GEMINI=${INSTALL_GEMINI:-S}
            
            if [[ "$INSTALL_GEMINI" =~ ^[Ss]$ ]]; then
                npm install -g @google/gemini-cli
                export NVM_DIR="$HOME/.nvm"
                [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
                
                GEMINI_BIN=$(command -v gemini)
                
                if [ -n "$GEMINI_BIN" ]; then
                    print_success "Gemini CLI instalado correctamente"
                else
                    print_error "Error instalando Gemini CLI"
                    return
                fi
            else
                print_warning "Saltando extensiones MCP"
                return
            fi
        else
            print_warning "Instala Node.js primero (opción 11) y npm packages (opción 12)"
            return
        fi
    fi
    
    print_info "Detectando versión de Gemini en $GEMINI_BIN..."
    GEMINI_VERSION=$(timeout 20s "$GEMINI_BIN" --version 2>/dev/null || echo "undetected")
    print_step "Procesando extensiones MCP en Gemini ($GEMINI_VERSION)..."
    
    declare -a extensions=(
        "https://github.com/ChromeDevTools/chrome-devtools-mcp"
        "https://github.com/github/github-mcp-server"
        "https://github.com/gemini-cli-extensions/postgres"
        "https://github.com/gemini-cli-extensions/nanobanana"
    )

    # Lista de extensiones ya instaladas para evitar prompts
    # Usamos el token exportado. Si falla la lista, asumimos vacía.
    INSTALLED_EXTS=$("$GEMINI_BIN" extensions list 2>/dev/null || echo "")

    for ext in "${extensions[@]}"; do
        # Extraer nombre base de la extensión para chequear si ya existe
        EXT_NAME=$(echo "$ext" | awk -F/ '{print $NF}')
        
        if echo "$INSTALLED_EXTS" | grep -q "$EXT_NAME"; then
            print_info "Extensión ya instalada: $EXT_NAME (Saltando...)"
            continue
        fi

        print_info "Instalando: $ext..."
        LOG_FILE=$(mktemp)
        
        # Usamos el token explícitamente y evitamos capturar stdout si causa problemas de TTY
        # pero logueamos errores filtrando el ruido de deprecación de Node
        if timeout 120s "$GEMINI_BIN" extensions install "$ext" --non-interactive > "$LOG_FILE" 2>&1; then
             print_success "Instalada: $ext"
        else
             if grep -qE "already installed|already registered" "$LOG_FILE"; then
                 print_info "La extensión ya estaba registrada (Saltando...)"
             else
                 # Si falló por timeout o falta de input, informar
                 print_warning "No se pudo instalar $ext automáticamente"
                 if [ -s "$LOG_FILE" ]; then
                     # Filtrar DeprecationWarning y líneas vacías para ver el error real
                     REAL_ERROR=$(grep -vE "DeprecationWarning|punycode|^[[:space:]]*$" "$LOG_FILE" | head -n 1 | cut -c1-120)
                     [ -n "$REAL_ERROR" ] && print_info "Detalle: $REAL_ERROR"
                 fi
             fi
        fi
        rm -f "$LOG_FILE"
    done
    
    print_info "Verificando actualizaciones de extensiones..."
    if timeout 60s "$GEMINI_BIN" extensions update --all &>/dev/null; then
        print_success "Todas las extensiones están actualizadas"
    else
        print_warning "Hubo un problema actualizando extensiones (no crítico)"
    fi

    print_success "Extensiones procesadas"
}

# ─────────────────────────────────────────────────────────────
# Instalación completa de Antigravity: reglas + workflows + settings.
# ─────────────────────────────────────────────────────────────
install_antigravity_full() {
    install_antigravity_rules
    install_antigravity_workflows
    install_gemini_settings
}
