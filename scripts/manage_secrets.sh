#!/bin/bash
# ==============================================================================
# GESTOR DE BÓVEDA Y SECRETOS EN PROTON PASS v3.0
# Compatible tanto con Notas ('dotfiles') como con Ítems Personalizados
# ==============================================================================

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPTS_DIR="$(dirname "$SCRIPT_PATH")"
DOTFILES_DIR="$(dirname "$SCRIPTS_DIR")"

# shellcheck disable=SC1091
source "$DOTFILES_DIR/scripts/common.sh"

# ─────────────────────────────────────────────────────────────
# Muestra el diagnóstico completo en español
# ─────────────────────────────────────────────────────────────
action_status() {
    load_pass_config
    print_header "ESTADO Y DIAGNÓSTICO DE PROTON PASS"

    if command -v pass-cli &>/dev/null; then
        echo -e "  ${WHITE}Binario CLI      :${NC} ${NEON_GREEN}$(command -v pass-cli)${NC} ($(pass-cli --version 2>/dev/null | head -1))"
    else
        echo -e "  ${WHITE}Binario CLI      :${NC} ${RED}No instalado${NC}"
    fi

    echo -e "  ${WHITE}Ubicación en Pass:${NC} ${NEON_CYAN}pass://${PROTON_PASS_VAULT}/${PROTON_PASS_ITEM}${NC}"
    echo ""

    if pass_is_logged_in; then
        print_success "Sesión activa en Proton Pass:"
        pass-cli info 2>/dev/null | sed 's/^/      /'
        echo ""
        print_step "Bóvedas (Vaults) disponibles en tu cuenta:"
        pass-cli vault list 2>/dev/null | sed 's/^/      /'
        echo ""
        print_step "Verificando secretos dentro de '${PROTON_PASS_VAULT}/${PROTON_PASS_ITEM}':"
        for field in GH_TOKEN RCLONE_TOKEN_JSON TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID; do
            local val
            val="$(pass_get_field "$field" || true)"
            if [ -n "$val" ]; then
                echo -e "      ${NEON_GREEN}✓${NC} ${WHITE}${field}${NC} ${GRAY}(encontrado en Proton Pass, longitud=${#val})${NC}"
            else
                echo -e "      ${YELLOW}○${NC} ${WHITE}${field}${NC} ${GRAY}(no encontrado aún en '${PROTON_PASS_ITEM}')${NC}"
            fi
        done
    else
        print_warning "No has iniciado sesión en Proton Pass CLI (o la sesión expiró)."
    fi

    echo ""
    print_step "Estado de archivos locales en este equipo:"
    if [ -f "$LOCAL_STAGED_SECRETS" ]; then
        echo -e "      ${NEON_GREEN}✓${NC} Copia local lista para subir: ${WHITE}$LOCAL_STAGED_SECRETS${NC}"
    else
        echo -e "      ${GRAY}○ Copia local temporal: no presente${NC}"
    fi
    if [ -f "$HOME/.config/rclone/rclone.conf" ]; then
        echo -e "      ${NEON_GREEN}✓${NC} Google Drive (Rclone)       : ${WHITE}~/.config/rclone/rclone.conf${NC}"
    else
        echo -e "      ${GRAY}○ Google Drive (Rclone)       : no configurado${NC}"
    fi
    if [ -f "$TELEGRAM_ENV_FILE" ]; then
        echo -e "      ${NEON_GREEN}✓${NC} Alertas de Telegram         : ${WHITE}~/.config/dotfiles/telegram.env${NC}"
    else
        echo -e "      ${GRAY}○ Alertas de Telegram         : no configurado${NC}"
    fi
}

# ─────────────────────────────────────────────────────────────
# Permite cambiar el nombre de la Bóveda (Vault) o Nota/Ítem
# ─────────────────────────────────────────────────────────────
action_configure_target() {
    load_pass_config
    print_header "CAMBIAR BÓVEDA O NOMBRE DE NOTA EN PROTON PASS"

    local new_vault new_item
    new_vault=$(ui_input "Nombre de la Bóveda (Vault) en Proton Pass" "$PROTON_PASS_VAULT")
    new_item=$(ui_input "Nombre de la Nota o Ítem de secretos" "$PROTON_PASS_ITEM")

    [ -n "$new_vault" ] && PROTON_PASS_VAULT="$new_vault"
    [ -n "$new_item" ] && PROTON_PASS_ITEM="$new_item"

    save_pass_config
    print_success "Ubicación actualizada a: pass://${PROTON_PASS_VAULT}/${PROTON_PASS_ITEM}"
}

# ─────────────────────────────────────────────────────────────
# Guarda los 4 secretos en Proton Pass.
# Soporta automáticamente si 'dotfiles' es una Nota (Note) o un Ítem.
# ─────────────────────────────────────────────────────────────
push_secrets_to_proton() {
    local gh_val="$1"
    local rclone_val="$2"
    local tg_tok_val="$3"
    local tg_chat_val="$4"

    load_pass_config
    ensure_pass_cli || return 1

    if ! pass_is_logged_in; then
        print_warning "Inicia sesión en Proton Pass para guardar tus secretos."
        pass_login_interactive || return 1
    fi

    # Asegurar que la bóveda exista
    if ! pass-cli item list --vault-name "$PROTON_PASS_VAULT" >/dev/null 2>&1; then
        print_step "Creando bóveda '${PROTON_PASS_VAULT}' en Proton Pass..."
        pass-cli vault create --name "$PROTON_PASS_VAULT" >/dev/null 2>&1 || true
    fi

    local note_content="# Secretos de Dotfiles (Gestionado con pass-cli)
GH_TOKEN=${gh_val}
RCLONE_TOKEN_JSON=${rclone_val}
TELEGRAM_BOT_TOKEN=${tg_tok_val}
TELEGRAM_CHAT_ID=${tg_chat_val}"

    # Verificar si ya existe la nota o ítem 'dotfiles' en la bóveda
    if pass-cli item view --vault-name "$PROTON_PASS_VAULT" --item-title "$PROTON_PASS_ITEM" >/dev/null 2>&1; then
        print_step "Actualizando '${PROTON_PASS_ITEM}' en la bóveda '${PROTON_PASS_VAULT}'..."

        # Intentar actualizar tanto el campo 'note' (si es una Nota) como campos individuales
        if pass-cli item update \
            --vault-name "$PROTON_PASS_VAULT" \
            --item-title "$PROTON_PASS_ITEM" \
            --field "note=$note_content" >/dev/null 2>&1; then
            # También intentar añadir/actualizar campos personalizados si el tipo de ítem lo permite
            pass-cli item update \
                --vault-name "$PROTON_PASS_VAULT" \
                --item-title "$PROTON_PASS_ITEM" \
                --field "GH_TOKEN=$gh_val" \
                --field "RCLONE_TOKEN_JSON=$rclone_val" \
                --field "TELEGRAM_BOT_TOKEN=$tg_tok_val" \
                --field "TELEGRAM_CHAT_ID=$tg_chat_val" >/dev/null 2>&1 || true
            print_success "Nota/Ítem '${PROTON_PASS_ITEM}' actualizado correctamente en Proton Pass."
            return 0
        elif pass-cli item update \
            --vault-name "$PROTON_PASS_VAULT" \
            --item-title "$PROTON_PASS_ITEM" \
            --field "GH_TOKEN=$gh_val" \
            --field "RCLONE_TOKEN_JSON=$rclone_val" \
            --field "TELEGRAM_BOT_TOKEN=$tg_tok_val" \
            --field "TELEGRAM_CHAT_ID=$tg_chat_val" >/dev/null 2>&1; then
            print_success "Ítem '${PROTON_PASS_ITEM}' actualizado correctamente en Proton Pass."
            return 0
        else
            print_error "No se pudo actualizar '${PROTON_PASS_ITEM}'."
            return 1
        fi
    else
        print_step "Creando nota '${PROTON_PASS_ITEM}' en la bóveda '${PROTON_PASS_VAULT}'..."
        if pass-cli item create note \
            --vault-name "$PROTON_PASS_VAULT" \
            --title "$PROTON_PASS_ITEM" \
            --note "$note_content" >/dev/null 2>&1; then
            print_success "Nota '${PROTON_PASS_ITEM}' creada con éxito en Proton Pass."
            return 0
        else
            print_error "No se pudo crear la nota '${PROTON_PASS_ITEM}' en Proton Pass."
            return 1
        fi
    fi
}

# ─────────────────────────────────────────────────────────────
# Sube los secretos locales hacia la nota 'dotfiles' en Proton Pass
# ─────────────────────────────────────────────────────────────
action_migrate() {
    print_header "SUBIR SECRETOS LOCALES A PROTON PASS"
    load_pass_config

    local GH_TOKEN="" RCLONE_TOKEN_JSON="" TELEGRAM_BOT_TOKEN="" TELEGRAM_CHAT_ID=""

    if [ -f "$LOCAL_STAGED_SECRETS" ]; then
        print_step "Leyendo tus secretos desde $LOCAL_STAGED_SECRETS..."
        set -a
        # shellcheck disable=SC1090
        source "$LOCAL_STAGED_SECRETS"
        set +a
    elif [ -f "$DOTFILES_DIR/.env.age" ]; then
        print_step "Desencriptando archivo antiguo .env.age..."
        ensure_package "age"
        local tmp_env
        tmp_env=$(mktemp)
        chmod 600 "$tmp_env"
        if age --decrypt -o "$tmp_env" "$DOTFILES_DIR/.env.age"; then
            set -a
            # shellcheck disable=SC1090
            source "$tmp_env"
            set +a
            rm -f "$tmp_env"
        else
            rm -f "$tmp_env"
            print_error "Contraseña incorrecta o fallo al leer .env.age."
            return 1
        fi
    else
        print_step "Recolectando secretos activos del sistema actual (gh, rclone, telegram)..."
        if command -v gh &>/dev/null; then
            GH_TOKEN="$(gh auth token 2>/dev/null || true)"
        fi
        if [ -f "$HOME/.config/rclone/rclone.conf" ]; then
            RCLONE_TOKEN_JSON="$(grep -E '^token[[:space:]]*=' "$HOME/.config/rclone/rclone.conf" | head -1 | sed -E 's/^token[[:space:]]*=[[:space:]]*//')"
        fi
        if [ -f "$TELEGRAM_ENV_FILE" ]; then
            # shellcheck disable=SC1090
            source "$TELEGRAM_ENV_FILE"
        fi
        if [ -z "$GH_TOKEN" ] && [ -z "$RCLONE_TOKEN_JSON" ] && [ -z "$TELEGRAM_BOT_TOKEN" ]; then
            print_warning "No se encontraron secretos locales pendientes."
            print_info "Usa la opción [5] para escribir o editar tus secretos directamente."
            return 1
        fi
    fi

    if push_secrets_to_proton "$GH_TOKEN" "$RCLONE_TOKEN_JSON" "$TELEGRAM_BOT_TOKEN" "$TELEGRAM_CHAT_ID"; then
        apply_loaded_secrets
        print_success "¡Tus secretos ya están guardados dentro de la nota '${PROTON_PASS_VAULT}/${PROTON_PASS_ITEM}'!"
        if [ -f "$LOCAL_STAGED_SECRETS" ]; then
            if ui_confirm "¿Deseas borrar la copia temporal local ($LOCAL_STAGED_SECRETS) ahora que ya está segura en Proton Pass?"; then
                shred -u "$LOCAL_STAGED_SECRETS" 2>/dev/null || rm -f "$LOCAL_STAGED_SECRETS"
                print_success "Copia temporal eliminada de forma segura."
            fi
        fi
        return 0
    fi
    return 1
}

# ─────────────────────────────────────────────────────────────
# Editor interactivo para crear o modificar secretos en Proton Pass
# ─────────────────────────────────────────────────────────────
action_push_interactive() {
    print_header "CREAR O EDITAR SECRETOS EN PROTON PASS"
    load_pass_config
    ensure_pass_cli || return 1

    if ! pass_is_logged_in; then
        pass_login_interactive || return 1
    fi

    local cur_gh cur_rclone cur_tg_tok cur_tg_chat
    cur_gh="$(pass_get_field "GH_TOKEN" || true)"
    cur_rclone="$(pass_get_field "RCLONE_TOKEN_JSON" || true)"
    cur_tg_tok="$(pass_get_field "TELEGRAM_BOT_TOKEN" || true)"
    cur_tg_chat="$(pass_get_field "TELEGRAM_CHAT_ID" || true)"

    if [ -f "$LOCAL_STAGED_SECRETS" ]; then
        # shellcheck disable=SC1090
        source "$LOCAL_STAGED_SECRETS"
        cur_gh="${cur_gh:-${GH_TOKEN:-}}"
        cur_rclone="${cur_rclone:-${RCLONE_TOKEN_JSON:-}}"
        cur_tg_tok="${cur_tg_tok:-${TELEGRAM_BOT_TOKEN:-}}"
        cur_tg_chat="${cur_tg_chat:-${TELEGRAM_CHAT_ID:-}}"
    fi

    echo -e "${GRAY}  Pulsa Enter dejando vacío cualquier campo para conservar su valor actual.${NC}"
    echo ""

    local in_gh in_rclone in_tg_tok in_tg_chat
    in_gh=$(ui_secret "Token de GitHub (GH_TOKEN)${cur_gh:+ [actual: configurado]}")
    in_rclone=$(ui_input "Token JSON de Rclone (RCLONE_TOKEN_JSON)" "${cur_rclone:+[actual: configurado]}")
    in_tg_tok=$(ui_secret "Token Bot de Telegram (TELEGRAM_BOT_TOKEN)${cur_tg_tok:+ [actual: configurado]}")
    in_tg_chat=$(ui_input "Chat ID de Telegram (TELEGRAM_CHAT_ID)" "${cur_tg_chat:-}")

    push_secrets_to_proton \
        "${in_gh:-$cur_gh}" \
        "${in_rclone:-$cur_rclone}" \
        "${in_tg_tok:-$cur_tg_tok}" \
        "${in_tg_chat:-$cur_tg_chat}"
}

# ─────────────────────────────────────────────────────────────
# Descarga los secretos de Proton Pass y los aplica al equipo
# ─────────────────────────────────────────────────────────────
action_pull() {
    print_header "SINCRONIZAR SECRETOS DESDE PROTON PASS A ESTE EQUIPO"
    unset SECRETS_LOADED
    unset GUEST_MODE

    if load_secrets; then
        if [ -n "${GH_TOKEN:-}" ] && command -v gh &>/dev/null; then
            if ! (unset GH_TOKEN GITHUB_TOKEN; gh auth status &>/dev/null); then
                print_step "Autenticando GitHub CLI (gh) con tu token..."
                echo "$GH_TOKEN" | (unset GH_TOKEN GITHUB_TOKEN; gh auth login --with-token) && (unset GH_TOKEN GITHUB_TOKEN; gh auth setup-git)
                print_success "GitHub CLI autenticado correctamente."
            fi
        fi
        return 0
    fi
    return 1
}

# ─────────────────────────────────────────────────────────────
# Gestión del Agente SSH de Proton Pass
# ─────────────────────────────────────────────────────────────
action_ssh_agent() {
    ensure_pass_cli || return 1
    if ! pass_is_logged_in; then
        pass_login_interactive || return 1
    fi

    print_header "AGENTE SSH DE PROTON PASS"
    local opt_load="🔑 Cargar llaves SSH de Proton Pass en la sesión actual (ssh-agent load)"
    local opt_start="🚀 Iniciar servicio en segundo plano (ssh-agent daemon start)"
    local opt_status="📊 Ver estado del servicio SSH Agent"
    local opt_stop="🛑 Detener servicio SSH Agent"
    local opt_back="↩️  Volver al menú anterior"

    local choice
    choice=$(ui_choose "Selecciona una acción para tus llaves SSH:" \
        "$opt_load" "$opt_start" "$opt_status" "$opt_stop" "$opt_back") || return 0

    case "$choice" in
        "$opt_load")
            if [ -z "${SSH_AUTH_SOCK:-}" ]; then
                eval "$(ssh-agent -s)" >/dev/null 2>&1
            fi
            pass-cli ssh-agent load
            ;;
        "$opt_start")
            pass-cli ssh-agent daemon start --log-file "$HOME/.ssh/proton-pass-agent.log"
            ;;
        "$opt_status")
            pass-cli ssh-agent daemon status
            ;;
        "$opt_stop")
            pass-cli ssh-agent daemon stop
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────
# Menú Interactivo en Español de Proton Pass
# ─────────────────────────────────────────────────────────────
show_menu() {
    while true; do
        clear
        load_pass_config

        local session_str="${YELLOW}Desconectado (Inicia sesión con la opción 2)${NC}"
        if pass_is_logged_in; then
            local acct
            acct=$(pass-cli info 2>/dev/null | grep -E "^- (Email|Username|Personal Access Token):" | head -1 | sed 's/^- //')
            session_str="${NEON_GREEN}Conectado (${acct:-Sesión activa})${NC}"
        fi

        local staging_str="${GRAY}Ninguno${NC}"
        if [ -f "$LOCAL_STAGED_SECRETS" ]; then
            staging_str="${NEON_CYAN}Listo para subir a Proton Pass (Opción 3)${NC}"
        fi

        echo ""
        echo -e "  ${NEON_CYAN}╭─────────────────────── 🔐 GESTOR DE PROTON PASS ───────────────────────╮${NC}"
        echo -e "  ${NEON_CYAN}│${NC}  ${NEON_GREEN}▸${NC} ${WHITE}Estado de Sesión :${NC} ${session_str}"
        echo -e "  ${NEON_CYAN}│${NC}  ${NEON_GREEN}▸${NC} ${WHITE}Nota / Ubicación :${NC} ${WHITE}pass://${PROTON_PASS_VAULT}/${PROTON_PASS_ITEM}${NC}"
        echo -e "  ${NEON_CYAN}│${NC}  ${NEON_GREEN}▸${NC} ${WHITE}Secretos Locales :${NC} ${staging_str}"
        echo -e "  ${NEON_CYAN}╰────────────────────────────────────────────────────────────────────────╯${NC}"
        echo ""

        echo -e "  ${NEON_GREEN}🔐 OPERACIONES DE BÓVEDA Y SECRETOS${NC}"
        echo -e "  ${GRAY}──────────────────────────────────────────────────────────────────────────${NC}"
        p_menu_item "1" "Ver Estado y Diagnóstico"       "Revisa conexión, bóvedas y qué tokens existen"
        p_menu_item "2" "Iniciar / Cambiar Sesión"       "Conecta tu cuenta Proton (Web, Terminal o PAT)"
        p_menu_item "3" "Subir Secretos a Proton Pass"   "Guarda tus tokens locales en la nota '${PROTON_PASS_ITEM}'"
        p_menu_item "4" "Descargar y Aplicar Secretos"   "Configura GitHub CLI, Rclone y Telegram desde Pass"
        p_menu_item "5" "Crear o Editar Secretos"        "Modifica tus tokens manualmente en Proton Pass"
        p_menu_item "6" "Agente de Llaves SSH"           "Carga tus llaves SSH guardadas en Proton Pass"
        p_menu_item "7" "Cambiar Bóveda o Nota Destino"  "Actual: Bóveda '${PROTON_PASS_VAULT}' / Nota '${PROTON_PASS_ITEM}'"
        p_menu_item "8" "Cerrar Sesión en este Equipo"   "Desconecta pass-cli de forma segura"
        echo -e "  ${GRAY}──────────────────────────────────────────────────────────────────────────${NC}"
        p_menu_item "0" "Volver / Salir"                 "Regresa al instalador principal o a la terminal"
        echo ""

        local choice
        echo -ne "  ${NEON_GREEN}❯${NC} ${WHITE}Selecciona una opción [0-8]: ${NC}"
        if [ -t 0 ]; then
            read -r choice </dev/tty
        else
            read -r choice || choice="0"
        fi

        case "$choice" in
            1) action_status ;;
            2) pass_login_interactive ;;
            3) action_migrate ;;
            4) action_pull ;;
            5) action_push_interactive ;;
            6) action_ssh_agent ;;
            7) action_configure_target ;;
            8) pass-cli logout && print_success "Sesión cerrada correctamente." ;;
            0|q|exit) exit 0 ;;
            *) print_error "Opción no válida."; sleep 1; continue ;;
        esac

        echo ""
        read -r -p "  [Presiona ENTER para continuar]..." </dev/tty
    done
}

# --- CLI ROUTER ---
if [ -n "${1:-}" ]; then
    case "$1" in
        status)    action_status ;;
        login)     pass_login_interactive ;;
        migrate)   action_migrate ;;
        pull|sync) action_pull ;;
        push|edit) action_push_interactive ;;
        ssh-agent) action_ssh_agent ;;
        run)
            shift
            [ "${1:-}" = "--" ] && shift
            ensure_pass_cli
            exec pass-cli run --env-file "$DOTFILES_DIR/.env.example" -- "$@"
            ;;
        *)
            echo "Uso: $0 {status|login|migrate|pull|push|ssh-agent|run -- <comando>}"
            exit 1
            ;;
    esac
    exit $?
fi

show_menu
