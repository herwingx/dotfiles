#!/bin/bash
# ==========================================
# VS CODE EXTENSIONS INSTALLER
# ==========================================
# Detecta tu editor (VS Code, Codium, Antigravity) e instala las extensiones
# definidas en .vscode-extensions
# ==========================================

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(dirname "$(dirname "$SCRIPT_PATH")")"
source "$DOTFILES_DIR/scripts/common.sh"

EXTENSIONS_FILE="$DOTFILES_DIR/.vscode-extensions"

# ─────────────────────────────────────────────────────────────
# Instala extensiones de VSCode
#
# Detecta el editor instalado (VS Code, Codium, Antigravity) e
# instala las extensiones listadas en el archivo `.vscode-extensions`.
#
# @sideeffects Ejecuta comandos del editor.
# ─────────────────────────────────────────────────────────────
install_vscode_extensions() {
    print_step "Buscando editor compatible..."

    EDITOR_CMD=$(detect_editor)

    if [ -z "$EDITOR_CMD" ]; then
        print_error "No se encontró ningún editor compatible (VS Code, Codium, Antigravity)."
        echo -e "${YELLOW}   Instala VS Code primero para cargar las extensiones.${NC}"
        return 1
    fi
    
    print_success "Detectado: $EDITOR_CMD"

    if [ ! -f "$EXTENSIONS_FILE" ]; then
        print_error "No se encontró el archivo .vscode-extensions"
        return 1
    fi

    print_step "Instalando extensiones para $EDITOR_CMD..."
    
    # Leer el archivo y filtrar líneas vacías o comentarios
    while IFS= read -r ext || [ -n "$ext" ]; do
        # Ignorar comentarios y líneas vacías
        [[ "$ext" =~ ^#.*$ ]] && continue
        [[ -z "$ext" ]] && continue
        
        # Trim whitespace
        ext=$(echo "$ext" | xargs)

        echo -e "${CYAN}   Installing: $ext${NC}"
        $EDITOR_CMD --install-extension "$ext" --force
        
    done < "$EXTENSIONS_FILE"

    print_success "Proceso finalizado."
}

# ─────────────────────────────────────────────────────────────
# Realiza backup de extensiones
#
# Guarda una lista de todas las extensiones instaladas
# actualmente en tu editor dentro del archivo `.vscode-extensions`.
#
# @sideeffects Sobrescribe el archivo `.vscode-extensions`.
# ─────────────────────────────────────────────────────────────
backup_extensions() {
    print_step "Buscando editor para backup..."
    
    EDITOR_CMD=$(detect_editor)

    if [ -z "$EDITOR_CMD" ]; then
        print_error "No se encontró editor para listar extensiones."
        return 1
    fi
    
    print_success "Detectado: $EDITOR_CMD"

    print_step "Guardando lista en $EXTENSIONS_FILE..."
    
    # Listar y limpiar (eliminar versiones si las muestra)
    $EDITOR_CMD --list-extensions > "$EXTENSIONS_FILE"
    
    # Verificar si escribió algo
    if [ -s "$EXTENSIONS_FILE" ]; then
        COUNT=$(wc -l < "$EXTENSIONS_FILE")
        print_success "$COUNT extensiones guardadas."
    else
        print_error "Error al guardar la lista."
    fi
}

# Router de argumentos
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ "$1" == "--backup" ]]; then
        backup_extensions
    else
        install_vscode_extensions
    fi
fi
