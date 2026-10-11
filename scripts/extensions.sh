#!/bin/bash
# ==============================================================================
# EXTENSIONS.SH - Gestor Idempotente de Extensiones (VS Code / Cursor / Codium)
# ==============================================================================

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(dirname "$(dirname "$SCRIPT_PATH")")"
# shellcheck disable=SC1091
source "$DOTFILES_DIR/scripts/common.sh"

EXTENSIONS_FILE="$DOTFILES_DIR/.vscode-extensions"

# ─────────────────────────────────────────────────────────────
# Instala extensiones de VS Code / Cursor de forma idempotente
# En servidores headless sin editor instalado, omite sin error.
# ─────────────────────────────────────────────────────────────
install_vscode_extensions() {
    print_step "Buscando editor compatible (Cursor, VS Code, VSCodium)..."

    local editor_cmd
    editor_cmd=$(detect_editor || true)

    if [ -z "$editor_cmd" ]; then
        if [ "$IS_SERVER" == "true" ]; then
            print_info "Entorno Server/Headless sin IDE gráfico: omitiendo extensiones."
            return 0
        fi
        print_warning "No se encontró VS Code, Cursor ni VSCodium instalado en el PATH."
        return 0
    fi

    print_success "Editor detectado: $editor_cmd"

    if [ ! -f "$EXTENSIONS_FILE" ]; then
        print_warning "No se encontró el archivo $EXTENSIONS_FILE"
        return 0
    fi

    print_step "Sincronizando extensiones para $editor_cmd..."

    # Obtener lista de extensiones ya instaladas (en minúsculas) para idempotencia rápida
    local installed_list
    installed_list="$($editor_cmd --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')"

    local installed_count=0
    local skipped_count=0

    while IFS= read -r ext || [ -n "$ext" ]; do
        ext=$(echo "$ext" | xargs)
        [[ -z "$ext" || "$ext" =~ ^# ]] && continue

        # Validar formato publisher.extension
        if [[ ! "$ext" =~ ^[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+$ ]]; then
            continue
        fi

        local ext_lower
        ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

        if grep -qxF "$ext_lower" <<< "$installed_list"; then
            skipped_count=$((skipped_count + 1))
            continue
        fi

        echo -e "${CYAN}   + Installing: ${WHITE}$ext${NC}"
        if $editor_cmd --install-extension "$ext" --force >/dev/null 2>&1; then
            installed_count=$((installed_count + 1))
        else
            print_warning "No se pudo instalar la extensión: $ext"
        fi
    done < "$EXTENSIONS_FILE"

    print_success "Extensiones listas ($installed_count nuevas instaladas, $skipped_count ya estaban instaladas)."
}

# ─────────────────────────────────────────────────────────────
# Respalda la lista de extensiones actualmente instaladas
# ─────────────────────────────────────────────────────────────
backup_extensions() {
    print_step "Buscando editor para respaldar extensiones..."

    local editor_cmd
    editor_cmd=$(detect_editor || true)

    if [ -z "$editor_cmd" ]; then
        print_error "No se encontró editor compatible (Cursor, VS Code, Codium)."
        return 1
    fi

    print_step "Exportando extensiones de $editor_cmd a $EXTENSIONS_FILE..."
    {
        echo "# VS Code / Cursor / VSCodium Extensions"
        $editor_cmd --list-extensions 2>/dev/null | grep -E '^[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+$' | sort -u
    } > "$EXTENSIONS_FILE"

    local count
    count=$(grep -cE '^[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+$' "$EXTENSIONS_FILE" || echo 0)
    print_success "$count extensiones respaldadas en .vscode-extensions."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ "${1:-}" == "--backup" ]]; then
        backup_extensions
    else
        install_vscode_extensions
    fi
fi
