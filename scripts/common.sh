#!/bin/bash
# ==============================================================================
# COMMON.SH - Motor Central, Detección de Distro/Perfil, UI y Proton Pass CLI
# Compatible con: Ubuntu/Debian y Fedora/RHEL (Servidor, Escritorio y WSL)
# ==============================================================================

# Asegurar conteo correcto de caracteres multibyte (tildes/iconos) incluso en servidores recién instalados
if locale -a 2>/dev/null | grep -qiE '^C\.utf-?8$'; then
    export LC_CTYPE="${LC_CTYPE:-C.UTF-8}"
fi

# --- PALETA DE COLORES (CYBERPUNK / TERMINAL MODERNA) ---
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'

RED='\033[0;31m'
GREEN='\033[0;32m'
NEON_GREEN='\033[1;32m' # Acento Principal
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NEON_CYAN='\033[1;36m'  # Acento Secundario
WHITE='\033[1;37m'
GRAY='\033[1;30m'
NC='\033[0m'

# --- DIRECTORIO BASE ---
if [ -z "${DOTFILES_DIR:-}" ]; then
    SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
    DOTFILES_DIR="$(dirname "$(dirname "$SCRIPT_PATH")")"
fi

# Asegurar que ~/.local/bin y mise shims estén en el PATH actual sin duplicar
path_prepend() {
    local dir="$1"
    if [ -d "$dir" ] && [[ ":$PATH:" != *":$dir:"* ]]; then
        export PATH="$dir:$PATH"
    fi
}
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/.local/share/mise/shims"

# --- DETECCIÓN INTELIGENTE DE PROVEEDOR DE LLAVE DE PROTON PASS ---
# Evita invalidar sesiones activas creadas con 'keyring' y usa 'fs' por defecto para persistir tras reinicios
configure_pass_key_provider() {
    local session_dir="${PROTON_PASS_SESSION_DIR:-$HOME/.local/share/proton-pass-cli/.session}"
    if [ -f "$session_dir/local.key" ]; then
        export PROTON_PASS_KEY_PROVIDER="fs"
    elif command -v pass-cli &>/dev/null && keyctl show 2>/dev/null | grep -q "@ProtonPassCLI" && env -u PROTON_PASS_KEY_PROVIDER pass-cli info >/dev/null 2>&1; then
        # Existe una sesión válida activa en el keyring del sistema; conservarla
        unset PROTON_PASS_KEY_PROVIDER
    else
        # Por defecto usar 'fs' (local.key) para que la sesión sobreviva reinicios en Server/Desktop/WSL
        export PROTON_PASS_KEY_PROVIDER="fs"
    fi
}
configure_pass_key_provider

# --- HELPERS VISUALES EN ESPAÑOL ---
print_header() {
    local text="${1^^}"
    local pad_len=$(( 69 - ${#text} ))
    [ "$pad_len" -lt 1 ] && pad_len=1
    local spaces
    printf -v spaces "%*s" "$pad_len" ""
    echo ""
    echo -e "  ${NEON_CYAN}╭──────────────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "  ${NEON_CYAN}│${NC} ${NEON_GREEN}▸ ${text}${spaces}${NEON_CYAN}│${NC}"
    echo -e "  ${NEON_CYAN}╰──────────────────────────────────────────────────────────────────────────╯${NC}"
}

print_step() {
    echo -e "${NEON_CYAN}  ▸ ${WHITE}$1${NC}"
}

print_success() {
    echo -e "${NEON_GREEN}  ✓ ${NC}$1"
}

print_warning() {
    echo -e "${YELLOW}  ⚠ AVISO: ${NC}$1"
}

print_error() {
    echo -e "${RED}  ✗ ERROR: ${NC}$1"
}

print_info() {
    echo -e "${GRAY}    • $1${NC}"
}

# Renderiza una fila de menú perfectamente alineada en español (sin desfase por tildes o emojis)
p_menu_item() {
    local num="$1"
    local title desc
    if [ "$#" -ge 4 ]; then
        title="$3"
        desc="$4"
    else
        title="$2"
        desc="$3"
    fi
    local pad_len=$(( 35 - ${#title} ))
    [ "$pad_len" -lt 1 ] && pad_len=1
    local spaces
    printf -v spaces "%*s" "$pad_len" ""
    printf "   ${GRAY}[${NEON_GREEN}%2s${GRAY}]${NC} ${WHITE}%s%s${NEON_CYAN}▸${NC} ${GRAY}%s${NC}\n" "$num" "$title" "$spaces" "$desc"
}

p_opt() {
    printf "${GRAY}[${WHITE}%2s${GRAY}]${NC} %-38s" "$1" "$2"
}

# --- INTERACTIVE TUI HELPERS (GUM + BASH PURO) ---
has_gum() {
    command -v gum &>/dev/null && [ -t 0 ] && [ -t 1 ]
}

ui_choose() {
    local header="$1"
    shift
    local options=("$@")

    if has_gum; then
        gum choose \
            --header="  $header" \
            --cursor="  ❯ " \
            --cursor.foreground="46" \
            --header.foreground="51" \
            --selected.foreground="46" \
            --height=15 \
            "${options[@]}"
        return $?
    fi

    echo -e "${NEON_CYAN}  $header${NC}" >&2
    local i=1
    for opt in "${options[@]}"; do
        printf "   ${GRAY}[${NEON_GREEN}%2d${GRAY}]${NC} %s\n" "$i" "$opt" >&2
        i=$((i + 1))
    done
    echo "" >&2
    local sel
    read -r -p "  ❯ Selecciona una opción [1-${#options[@]}]: " sel </dev/tty
    if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le "${#options[@]}" ]; then
        echo "${options[$((sel - 1))]}"
        return 0
    fi
    return 1
}

ui_choose_multi() {
    local header="$1"
    shift
    local options=("$@")

    if has_gum; then
        gum choose --no-limit \
            --header="  $header (Espacio = marcar, Enter = confirmar)" \
            --cursor="  ❯ " \
            --cursor.foreground="46" \
            --header.foreground="51" \
            --selected.foreground="46" \
            --height=16 \
            "${options[@]}"
        return $?
    fi

    echo -e "${NEON_CYAN}  $header${NC}" >&2
    local i=1
    for opt in "${options[@]}"; do
        printf "   ${GRAY}[${NEON_GREEN}%2d${GRAY}]${NC} %s\n" "$i" "$opt" >&2
        i=$((i + 1))
    done
    echo "" >&2
    local sel
    read -r -p "  ❯ Opciones separadas por coma (ej. 1,3,5): " sel </dev/tty
    IFS=',' read -ra idxs <<< "$sel"
    for idx in "${idxs[@]}"; do
        idx=$(echo "$idx" | xargs)
        if [[ "$idx" =~ ^[0-9]+$ ]] && [ "$idx" -ge 1 ] && [ "$idx" -le "${#options[@]}" ]; then
            echo "${options[$((idx - 1))]}"
        fi
    done
}

ui_confirm() {
    local prompt="$1"
    if has_gum; then
        gum confirm "  $prompt" \
            --prompt.foreground="51" \
            --selected.background="46" \
            --selected.foreground="0" \
            --affirmative="Sí" \
            --negative="No"
        return $?
    fi
    local ans
    echo -ne "${NEON_GREEN}  ❯ ${WHITE}${prompt} [s/N]: ${NC}" >&2
    read -r ans </dev/tty
    [[ "$ans" =~ ^[YySs]$ ]]
}

ui_input() {
    local prompt="$1"
    local placeholder="${2:-}"
    if has_gum; then
        gum input --prompt="  ❯ $prompt: " --placeholder="$placeholder" --prompt.foreground="46"
        return $?
    fi
    local val
    echo -ne "${NEON_CYAN}  ❯ ${WHITE}${prompt}${GRAY}${placeholder:+ ($placeholder)}${NC}: " >&2
    read -r val </dev/tty
    echo "$val"
}

ui_secret() {
    local prompt="$1"
    if has_gum; then
        gum input --password --prompt="  🔑 $prompt: " --prompt.foreground="226"
        return $?
    fi
    local val
    echo -ne "${YELLOW}  🔑 ${WHITE}${prompt}: ${NC}" >&2
    read -r -s val </dev/tty
    echo "" >&2
    echo "$val"
}

# --- DETECCIÓN DE SISTEMA OPERATIVO (UBUNTU/DEBIAN & FEDORA/RHEL) ---
if [ "$(id -u)" -eq 0 ]; then
    SUDO_CMD=""
else
    SUDO_CMD="sudo"
fi

OS_TYPE="unknown"
OS_ID="unknown"
OS_PRETTY_NAME="Linux"
OS_VERSION_ID=""
IS_DNF5=false

if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_PRETTY_NAME="${PRETTY_NAME:-$ID}"
    OS_VERSION_ID="${VERSION_ID:-}"

    case "$ID" in
        ubuntu|debian|linuxmint|pop)
            OS_TYPE="debian"
            PKG_MANAGER="apt-get"
            PKG_UPDATE_CMD="$SUDO_CMD env DEBIAN_FRONTEND=noninteractive apt-get update -y"
            PKG_INSTALL_CMD="$SUDO_CMD env DEBIAN_FRONTEND=noninteractive apt-get install -y"
            ;;
        fedora|rhel|centos|almalinux|rocky)
            OS_TYPE="redhat"
            PKG_MANAGER="dnf"
            PKG_UPDATE_CMD="$SUDO_CMD dnf check-update"
            PKG_INSTALL_CMD="$SUDO_CMD dnf install -y"
            if command -v dnf &>/dev/null && dnf --version 2>/dev/null | head -1 | grep -q "dnf5"; then
                IS_DNF5=true
            fi
            ;;
        *)
            if [[ "${ID_LIKE:-}" == *"debian"* ]] || [[ "${ID_LIKE:-}" == *"ubuntu"* ]]; then
                OS_TYPE="debian"
                PKG_MANAGER="apt-get"
                PKG_UPDATE_CMD="$SUDO_CMD env DEBIAN_FRONTEND=noninteractive apt-get update -y"
                PKG_INSTALL_CMD="$SUDO_CMD env DEBIAN_FRONTEND=noninteractive apt-get install -y"
            elif [[ "${ID_LIKE:-}" == *"fedora"* ]] || [[ "${ID_LIKE:-}" == *"rhel"* ]]; then
                OS_TYPE="redhat"
                PKG_MANAGER="dnf"
                PKG_UPDATE_CMD="$SUDO_CMD dnf check-update"
                PKG_INSTALL_CMD="$SUDO_CMD dnf install -y"
            fi
            ;;
    esac
fi

# Detectar perfil de ejecución: WSL, Servidor o Escritorio
IS_WSL=false
IS_CONTAINER=false
IS_DESKTOP=false
IS_SERVER=false
SESSION_DISPLAY_TYPE="headless"
ENV_PROFILE="server"
ENV_PROFILE_LABEL="SERVIDOR (Sin entorno gráfico)"

if grep -qi microsoft /proc/version 2>/dev/null || [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
    IS_WSL=true
    ENV_PROFILE="wsl"
    SESSION_DISPLAY_TYPE="wsl"
    ENV_PROFILE_LABEL="WINDOWS WSL2"
elif [ -f /.dockerenv ] || [ -f /run/.containerenv ] || grep -qa "container=" /proc/1/environ 2>/dev/null; then
    IS_CONTAINER=true
    IS_SERVER=true
    ENV_PROFILE="server"
    SESSION_DISPLAY_TYPE="contenedor"
    ENV_PROFILE_LABEL="SERVIDOR CONTENEDOR (LXC/Docker)"
elif [ -n "${XDG_CURRENT_DESKTOP:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ] || [[ "${XDG_SESSION_TYPE:-}" =~ ^(wayland|x11)$ ]]; then
    IS_DESKTOP=true
    ENV_PROFILE="desktop"
    if [ "${XDG_SESSION_TYPE:-}" = "wayland" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
        SESSION_DISPLAY_TYPE="Wayland"
    else
        SESSION_DISPLAY_TYPE="X11"
    fi
    ENV_PROFILE_LABEL="ESCRITORIO (${SESSION_DISPLAY_TYPE})"
else
    IS_SERVER=true
    ENV_PROFILE="server"
    SESSION_DISPLAY_TYPE="Headless"
    ENV_PROFILE_LABEL="SERVIDOR (Headless)"
fi

run_pkg_index_update() {
    if [ "$OS_TYPE" = "debian" ]; then
        $SUDO_CMD env DEBIAN_FRONTEND=noninteractive apt-get update -y
        return $?
    elif [ "$OS_TYPE" = "redhat" ]; then
        $SUDO_CMD dnf check-update >/dev/null
        local rc=$?
        if [ $rc -eq 0 ] || [ $rc -eq 100 ]; then
            return 0
        fi
        return $rc
    fi
    return 0
}

# --- FUNCIONES CORE ---

ensure_package() {
    local package="$1"
    local binary="${2:-$package}"

    if command -v "$binary" &> /dev/null; then
        print_info "Paquete '$package' ya disponible (binario: $binary)."
        return 0
    fi

    local installed=false
    case "$OS_TYPE" in
        debian)
            dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "ok installed" && installed=true
            ;;
        redhat)
            rpm -q "$package" &> /dev/null && installed=true
            ;;
    esac

    if [ "$installed" = true ]; then
        print_info "Paquete '$package' ya instalado en el sistema."
        return 0
    fi

    print_step "Instalando paquete '$package' ($OS_ID)..."
    if $PKG_INSTALL_CMD "$package"; then
        print_success "Paquete '$package' instalado."
        return 0
    else
        print_error "No se pudo instalar '$package'."
        return 1
    fi
}

# Instala una lista de especificaciones "paquete:binario" en una sola transacción de apt/dnf
ensure_packages_batch() {
    local missing_pkgs=()
    local present_count=0

    for spec in "$@"; do
        local pkg="${spec%%:*}"
        local bin="${spec##*:}"
        [ -z "$bin" ] && bin="$pkg"

        if command -v "$bin" &>/dev/null; then
            present_count=$((present_count + 1))
            continue
        fi

        local is_inst=false
        case "$OS_TYPE" in
            debian)
                dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed" && is_inst=true
                ;;
            redhat)
                rpm -q "$pkg" &>/dev/null && is_inst=true
                ;;
        esac

        if [ "$is_inst" = true ]; then
            present_count=$((present_count + 1))
        else
            missing_pkgs+=("$pkg")
        fi
    done

    if [ "${#missing_pkgs[@]}" -eq 0 ]; then
        print_info "Todos los paquetes base verificados ($present_count ya instalados)."
        return 0
    fi

    print_step "Instalando ${#missing_pkgs[@]} paquete(s) faltante(s) en lote (${missing_pkgs[*]})..."
    if $PKG_INSTALL_CMD "${missing_pkgs[@]}"; then
        print_success "Paquetes instalados correctamente (${missing_pkgs[*]})."
        return 0
    fi

    print_warning "Instalación en lote reportó aviso; reintentando paquete por paquete..."
    for pkg in "${missing_pkgs[@]}"; do
        ensure_package "$pkg" "$pkg" || true
    done
}

update_bashrc_block() {
    local name="$1"
    local content="$2"
    local mode="${3:-bottom}"
    local bashrc="$HOME/.bashrc"

    [ -f "$bashrc" ] || touch "$bashrc"

    local start="<!-- BEGIN_${name} -->"
    local end="<!-- END_${name} -->"

    sed -i "/$start/,/$end/d" "$bashrc"

    local block="# $start
$content
# $end"

    if [ "$mode" == "top" ]; then
        cp "$bashrc" "$bashrc.tmp"
        printf "%s\n\n" "$block" > "$bashrc"
        cat "$bashrc.tmp" >> "$bashrc"
        rm -f "$bashrc.tmp"
    else
        printf "\n%s\n" "$block" >> "$bashrc"
    fi
}

detect_editor() {
    local editors=("cursor" "code" "codium")
    for cmd in "${editors[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            echo "$cmd"
            return 0
        fi
    done
    return 1
}

# ==============================================================================
# 🔐 MOTOR DE SECRETOS CON PROTON PASS CLI (SOPORTA NOTAS E ÍTEMS)
# ==============================================================================

PROTON_PASS_CONFIG_DIR="$HOME/.config/dotfiles"
PROTON_PASS_CONF="$PROTON_PASS_CONFIG_DIR/pass.conf"
LOCAL_STAGED_SECRETS="$PROTON_PASS_CONFIG_DIR/secrets.env"
TELEGRAM_ENV_FILE="$PROTON_PASS_CONFIG_DIR/telegram.env"

load_pass_config() {
    PROTON_PASS_VAULT="${PROTON_PASS_VAULT:-Personal}"
    PROTON_PASS_ITEM="${PROTON_PASS_ITEM:-dotfiles}"
    if [ -f "$PROTON_PASS_CONF" ]; then
        # shellcheck disable=SC1090
        source "$PROTON_PASS_CONF"
    fi
}

save_pass_config() {
    mkdir -p "$PROTON_PASS_CONFIG_DIR"
    chmod 700 "$PROTON_PASS_CONFIG_DIR"
    cat > "$PROTON_PASS_CONF" <<EOF
PROTON_PASS_VAULT="${PROTON_PASS_VAULT:-Personal}"
PROTON_PASS_ITEM="${PROTON_PASS_ITEM:-dotfiles}"
EOF
    chmod 600 "$PROTON_PASS_CONF"
}

ensure_pass_cli() {
    path_prepend "$HOME/.local/bin"

    if command -v pass-cli &> /dev/null; then
        print_info "Proton Pass CLI listo ($(pass-cli --version 2>/dev/null | head -1))."
        return 0
    fi

    print_step "Instalando Proton Pass CLI (pass-cli)..."
    ensure_package "curl"
    ensure_package "jq"
    ensure_package "ca-certificates"

    mkdir -p "$HOME/.local/bin"
    if PROTON_PASS_CLI_INSTALL_DIR="$HOME/.local/bin" bash -c "$(curl -fsSL https://proton.me/download/pass-cli/install.sh)"; then
        path_prepend "$HOME/.local/bin"
        if command -v pass-cli &> /dev/null; then
            mkdir -p "$HOME/.local/share/bash-completion/completions"
            pass-cli completions bash > "$HOME/.local/share/bash-completion/completions/pass-cli" 2>/dev/null || true
            print_success "Proton Pass CLI instalado en ~/.local/bin/pass-cli"
            return 0
        fi
    fi

    print_error "No se pudo instalar Proton Pass CLI."
    return 1
}

pass_is_logged_in() {
    command -v pass-cli &>/dev/null || return 1
    configure_pass_key_provider

    local out
    out="$(pass-cli info 2>&1)"
    local rc=$?

    if grep -qE "Failed to open encrypted database|Local encryption key not found" <<< "$out"; then
        pass-cli logout --force >/dev/null 2>&1 || true
        export PROTON_PASS_KEY_PROVIDER="fs"
        return 1
    fi

    if [ $rc -eq 0 ] && grep -qE "^- (ID|Username|Email|Personal Access Token):" <<< "$out"; then
        return 0
    fi
    return 1
}

# ─────────────────────────────────────────────────────────────
# Obtiene un secreto desde Proton Pass (soporta tanto campos
# individuales como contenido KEY=VALUE dentro de una Nota 'dotfiles')
# ─────────────────────────────────────────────────────────────
pass_get_field() {
    local field="$1"
    load_pass_config

    local items_to_try=("$PROTON_PASS_ITEM")
    if [ "$PROTON_PASS_ITEM" = "dotfiles" ]; then
        items_to_try+=("Dotfiles")
    elif [ "$PROTON_PASS_ITEM" = "Dotfiles" ]; then
        items_to_try+=("dotfiles")
    fi

    local item_name val note_body
    for item_name in "${items_to_try[@]}"; do
        # 1. Intentar leer como campo directo del ítem
        val="$(pass-cli item view "pass://${PROTON_PASS_VAULT}/${item_name}/${field}" 2>/dev/null || true)"
        if [ -n "$val" ]; then
            printf "%s" "$val"
            return 0
        fi

        # 2. Intentar leer dentro del texto de la Nota (formato KEY=VALUE)
        note_body="$(pass-cli item view "pass://${PROTON_PASS_VAULT}/${item_name}/note" 2>/dev/null || true)"
        if [ -n "$note_body" ]; then
            val="$(grep -E "^[[:space:]]*(export[[:space:]]+)?${field}=" <<< "$note_body" | tail -n 1 | sed -E "s/^[[:space:]]*(export[[:space:]]+)?${field}=//" | sed -E 's/^"(.*)"$/\1/; s/^'\''(.*)'\''$/\1/')"
            if [ -n "$val" ]; then
                printf "%s" "$val"
                return 0
            fi
        fi
    done

    return 1
}

apply_loaded_secrets() {
    local applied=0

    if [ -n "${GH_TOKEN:-}" ]; then
        export GH_TOKEN
        export GITHUB_TOKEN="$GH_TOKEN"
        print_success "Token de GitHub (GH_TOKEN) cargado en la sesión."
        applied=$((applied + 1))
    fi

    if [ -n "${RCLONE_TOKEN_JSON:-}" ]; then
        mkdir -p "$HOME/.config/rclone"
        cat > "$HOME/.config/rclone/rclone.conf" <<EOF
[gdrive]
type = drive
scope = drive
token = $RCLONE_TOKEN_JSON
team_drive =
EOF
        chmod 600 "$HOME/.config/rclone/rclone.conf"
        print_success "Google Drive configurado en Rclone (~/.config/rclone/rclone.conf)."
        applied=$((applied + 1))
    fi

    if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
        mkdir -p "$PROTON_PASS_CONFIG_DIR"
        chmod 700 "$PROTON_PASS_CONFIG_DIR"
        cat > "$TELEGRAM_ENV_FILE" <<EOF
# Generado automáticamente por Dotfiles Proton Pass Manager
TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
TELEGRAM_CHAT_ID="$TELEGRAM_CHAT_ID"
EOF
        chmod 600 "$TELEGRAM_ENV_FILE"
        print_success "Notificaciones de Telegram configuradas (~/.config/dotfiles/telegram.env)."
        applied=$((applied + 1))
    fi

    if [ $applied -gt 0 ]; then
        export SECRETS_LOADED=1
        return 0
    fi
    return 1
}

pass_login_interactive() {
    ensure_pass_cli || return 1

    if pass_is_logged_in; then
        print_success "Sesión activa en Proton Pass."
        pass-cli info 2>/dev/null | sed 's/^/    /'
        return 0
    fi

    # Asegurar que el nuevo inicio de sesión persista en disco (local.key)
    export PROTON_PASS_KEY_PROVIDER="fs"

    print_header "INICIAR SESIÓN EN PROTON PASS CLI"
    echo -e "${GRAY}  Entorno detectado: ${NEON_CYAN}${ENV_PROFILE_LABEL}${GRAY} (${OS_PRETTY_NAME})${NC}"
    echo ""

    local opt_web="🌐 Inicio por Navegador Web (Muestra enlace seguro - Soporta 2FA y Passkeys)"
    local opt_cli="⌨️  Inicio en Terminal (Correo + Contraseña + Código 2FA directo en consola)"
    local opt_pat="🤖 Token de Acceso Personal (PAT - Ideal para Servidores sin navegador)"
    local opt_skip="🚀 Omitir por ahora (Modo Invitado - Instalar todo sin credenciales)"

    local choice
    choice=$(ui_choose "Elige cómo deseas iniciar sesión en Proton Pass:" \
        "$opt_web" "$opt_cli" "$opt_pat" "$opt_skip") || return 1

    case "$choice" in
        "$opt_web")
            print_step "Iniciando autenticación por navegador..."
            pass-cli login
            ;;
        "$opt_cli")
            local email
            email=$(ui_input "Correo de tu cuenta Proton" "usuario@proton.me")
            if [ -n "$email" ]; then
                pass-cli login --interactive "$email"
            else
                pass-cli login --interactive
            fi
            ;;
        "$opt_pat")
            local pat
            pat=$(ui_secret "Pega tu Token de Acceso Personal (pst_...)")
            if [ -n "$pat" ]; then
                PROTON_PASS_PERSONAL_ACCESS_TOKEN="$pat" pass-cli login
            fi
            ;;
        *)
            print_warning "Modo Invitado activado: se omitirá la conexión con Proton Pass."
            export GUEST_MODE=true
            return 0
            ;;
    esac

    if pass_is_logged_in; then
        print_success "Sesión iniciada correctamente en Proton Pass."
        return 0
    else
        print_error "No se pudo completar el inicio de sesión."
        return 1
    fi
}

load_secrets() {
    if [ "${SECRETS_LOADED:-}" = "1" ]; then
        return 0
    fi

    if [ "${GUEST_MODE:-}" = "true" ]; then
        print_info "Modo Invitado activo: omitiendo carga de secretos."
        return 0
    fi

    load_pass_config
    ensure_pass_cli || true

    # 1. Si hay sesión activa en Proton Pass, leer desde la nota/ítem 'dotfiles'
    if pass_is_logged_in; then
        print_step "Leyendo secretos desde Proton Pass (pass://${PROTON_PASS_VAULT}/${PROTON_PASS_ITEM})..."
        local v_gh v_rclone v_tg_tok v_tg_chat
        v_gh="$(pass_get_field "GH_TOKEN" || true)"
        v_rclone="$(pass_get_field "RCLONE_TOKEN_JSON" || true)"
        v_tg_tok="$(pass_get_field "TELEGRAM_BOT_TOKEN" || true)"
        v_tg_chat="$(pass_get_field "TELEGRAM_CHAT_ID" || true)"

        [ -n "$v_gh" ] && GH_TOKEN="$v_gh"
        [ -n "$v_rclone" ] && RCLONE_TOKEN_JSON="$v_rclone"
        [ -n "$v_tg_tok" ] && TELEGRAM_BOT_TOKEN="$v_tg_tok"
        [ -n "$v_tg_chat" ] && TELEGRAM_CHAT_ID="$v_tg_chat"

        if apply_loaded_secrets; then
            return 0
        fi
        print_warning "Aún no hay secretos guardados dentro de 'pass://${PROTON_PASS_VAULT}/${PROTON_PASS_ITEM}'."
    fi

    # 2. Respaldo: Secretos locales pre-etapados (~/.config/dotfiles/secrets.env)
    if [ -f "$LOCAL_STAGED_SECRETS" ]; then
        print_step "Cargando secretos desde copia local segura ($LOCAL_STAGED_SECRETS)..."
        set -a
        # shellcheck disable=SC1090
        source "$LOCAL_STAGED_SECRETS"
        set +a
        if apply_loaded_secrets; then
            if pass_is_logged_in; then
                print_info "Consejo: Usa la opción [9] del menú para subir estos secretos a tu nota 'dotfiles' en Proton Pass."
            fi
            return 0
        fi
    fi

    # 3. En ejecución desatendida sin terminal, activar Modo Invitado automáticamente
    if [ "${AUTO_INSTALL:-}" = "true" ] && [ ! -t 0 ]; then
        print_warning "Sin sesión activa en Proton Pass. Continuando en Modo Invitado."
        export GUEST_MODE=true
        return 0
    fi

    # 4. Preguntar interactivamente en distros limpias
    print_header "CONFIGURACIÓN DE CREDENCIALES (PROTON PASS)"
    echo -e "${GRAY}  No se detectó sesión activa de Proton Pass ni credenciales locales.${NC}"
    echo -e "${GRAY}  Recuerda: Todo el sistema, Mise, Docker y herramientas web se instalan${NC}"
    echo -e "${GRAY}  sin problemas aunque elijas el Modo Invitado.${NC}"
    echo ""

    local opt_login="🔐 Iniciar sesión en Proton Pass ahora y sincronizar mis secretos"
    local opt_guest="🚀 Continuar en Modo Invitado (Instalar todo sin credenciales y configurar luego)"

    local action
    action=$(ui_choose "¿Cómo deseas continuar en este equipo?" "$opt_login" "$opt_guest") || {
        export GUEST_MODE=true
        return 0
    }

    if [ "$action" = "$opt_login" ]; then
        if pass_login_interactive && pass_is_logged_in; then
            local v_gh v_rclone v_tg_tok v_tg_chat
            v_gh="$(pass_get_field "GH_TOKEN" || true)"
            v_rclone="$(pass_get_field "RCLONE_TOKEN_JSON" || true)"
            v_tg_tok="$(pass_get_field "TELEGRAM_BOT_TOKEN" || true)"
            v_tg_chat="$(pass_get_field "TELEGRAM_CHAT_ID" || true)"

            [ -n "$v_gh" ] && GH_TOKEN="$v_gh"
            [ -n "$v_rclone" ] && RCLONE_TOKEN_JSON="$v_rclone"
            [ -n "$v_tg_tok" ] && TELEGRAM_BOT_TOKEN="$v_tg_tok"
            [ -n "$v_tg_chat" ] && TELEGRAM_CHAT_ID="$v_tg_chat"

            if apply_loaded_secrets; then
                return 0
            else
                print_warning "Sesión iniciada, pero la nota/ítem '${PROTON_PASS_ITEM}' aún no tiene los tokens."
                print_info "Usa './scripts/manage_secrets.sh' para rellenar tu nota 'dotfiles' en Proton Pass."
                return 0
            fi
        fi
    fi

    print_info "Modo Invitado activo. Puedes ejecutar './install.sh --secrets' cuando quieras."
    export GUEST_MODE=true
    return 0
}

decrypt_secrets() {
    load_secrets "$@"
}

reload_shell() {
    print_header "Recargando Terminal"
    echo -e "${GREEN}  Aplicando todos los cambios en tu sesión... 🚀${NC}"
    echo ""
    exec bash
}
