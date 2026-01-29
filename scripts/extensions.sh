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

install_vscode_extensions() {
    echo -e "${GREEN}>>> Buscando editor compatible...${NC}"

    # Lista de binarios soportados en orden de preferencia
    EDITORS=("code" "codium" "antigravity" "agy" "cursor")
    EDITOR_CMD=""

    for cmd in "${EDITORS[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            EDITOR_CMD="$cmd"
            echo -e "${CYAN}   ✓ Detectado: $cmd${NC}"
            break
        fi
    done

    if [ -z "$EDITOR_CMD" ]; then
        echo -e "${RED}   ✗ No se encontró ningún editor compatible (VS Code, Codium, Antigravity).${NC}"
        echo -e "${YELLOW}   Instala VS Code primero para cargar las extensiones.${NC}"
        # Opcional: Ofrecer instalar VS Code en Fedora/Ubuntu?
        return 1
    fi

    if [ ! -f "$EXTENSIONS_FILE" ]; then
        echo -e "${RED}   ✗ No se encontró el archivo .vscode-extensions${NC}"
        return 1
    fi

    echo -e "${GREEN}>>> Instalando extensiones para $EDITOR_CMD...${NC}"
    
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

    echo -e "${GREEN}>>> Proceso finalizado.${NC}"
}

backup_extensions() {
    echo -e "${GREEN}>>> Buscando editor para backup...${NC}"
    
    # Misma lógica de detección
    EDITORS=("code" "codium" "antigravity" "agy" "cursor")
    EDITOR_CMD=""

    for cmd in "${EDITORS[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            EDITOR_CMD="$cmd"
            echo -e "${CYAN}   ✓ Detectado: $cmd${NC}"
            break
        fi
    done

    if [ -z "$EDITOR_CMD" ]; then
        echo -e "${RED}   ✗ No se encontró editor para listar extensiones.${NC}"
        return 1
    fi

    echo -e "${GREEN}>>> Guardando lista en $EXTENSIONS_FILE...${NC}"
    
    # Listar y limpiar (eliminar versiones si las muestra)
    $EDITOR_CMD --list-extensions > "$EXTENSIONS_FILE"
    
    # Verificar si escribió algo
    if [ -s "$EXTENSIONS_FILE" ]; then
        COUNT=$(wc -l < "$EXTENSIONS_FILE")
        echo -e "${CYAN}   ✓ $COUNT extensiones guardadas.${NC}"
    else
        echo -e "${RED}   ✗ Error al guardar la lista.${NC}"
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
