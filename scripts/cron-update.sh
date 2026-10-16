#!/bin/bash
# ==============================================================================
# CRON-UPDATE.SH - Actualizaciones Automáticas (Ubuntu & Fedora Server/Desktop)
# Ejecutado por cron con notificaciones a Telegram (configurado vía Proton Pass)
# ==============================================================================

LOG_DIR="$HOME/.local/state/dotfiles"
LOG_FILE="$LOG_DIR/updates.log"
CONFIG_FILE="$HOME/.config/dotfiles/telegram.env"
PASS_CONF="$HOME/.config/dotfiles/pass.conf"

HOSTNAME="${HOSTNAME:-$(cat /etc/hostname 2>/dev/null || hostname 2>/dev/null || echo 'unknown')}"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

export PROTON_PASS_KEY_PROVIDER="${PROTON_PASS_KEY_PROVIDER:-fs}"
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

PROTON_PASS_VAULT="${PROTON_PASS_VAULT:-Personal}"
PROTON_PASS_ITEM="${PROTON_PASS_ITEM:-dotfiles}"
if [ -f "$PASS_CONF" ]; then
    # shellcheck disable=SC1090
    source "$PASS_CONF"
fi

# 1. Cargar credenciales de Telegram desde archivo local o Proton Pass CLI
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
elif command -v pass-cli &>/dev/null && pass-cli info >/dev/null 2>&1; then
    TELEGRAM_BOT_TOKEN="$(pass-cli item view "pass://${PROTON_PASS_VAULT}/${PROTON_PASS_ITEM}/TELEGRAM_BOT_TOKEN" 2>/dev/null || true)"
    TELEGRAM_CHAT_ID="$(pass-cli item view "pass://${PROTON_PASS_VAULT}/${PROTON_PASS_ITEM}/TELEGRAM_CHAT_ID" 2>/dev/null || true)"
    if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
        NOTE_BODY="$(pass-cli item view "pass://${PROTON_PASS_VAULT}/${PROTON_PASS_ITEM}/note" 2>/dev/null || true)"
        [ -z "$TELEGRAM_BOT_TOKEN" ] && TELEGRAM_BOT_TOKEN="$(grep -E "^(export[[:space:]]+)?TELEGRAM_BOT_TOKEN=" <<< "$NOTE_BODY" | head -1 | cut -d'=' -f2- | sed -E 's/^["'\''](.*)["'\'']$/\1/')"
        [ -z "$TELEGRAM_CHAT_ID" ] && TELEGRAM_CHAT_ID="$(grep -E "^(export[[:space:]]+)?TELEGRAM_CHAT_ID=" <<< "$NOTE_BODY" | head -1 | cut -d'=' -f2- | sed -E 's/^["'\''](.*)["'\'']$/\1/')"
    fi
fi

send_telegram() {
    local message="$1"
    local type="${2:-info}"

    if [ -z "${TELEGRAM_BOT_TOKEN:-}" ] || [ -z "${TELEGRAM_CHAT_ID:-}" ]; then
        return 1
    fi

    local emoji="ℹ️"
    case "$type" in
        success) emoji="✅" ;;
        warning) emoji="⚠️" ;;
        error)   emoji="❌" ;;
        reboot)  emoji="🔄" ;;
    esac

    local full_message="${emoji} <b>[${HOSTNAME}]</b>
${message}

🕐 ${DATE}"

    curl -fsS -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$full_message" \
        -d parse_mode="HTML" > /dev/null 2>&1 || true
}

log() {
    local level="$1"
    local message="$2"
    echo "[$DATE] [$level] $message" >> "$LOG_FILE"
}

check_kernel_update() {
    local current_kernel
    current_kernel=$(uname -r)

    if [ -f /etc/debian_version ]; then
        local latest_kernel
        latest_kernel=$(ls -1 /boot/vmlinuz-* 2>/dev/null | sort -V | tail -1 | sed 's|/boot/vmlinuz-||')
        if [ -n "$latest_kernel" ] && [ "$latest_kernel" != "$current_kernel" ]; then
            return 0
        fi
    elif [ -f /etc/redhat-release ]; then
        local latest_kernel
        latest_kernel=$(rpm -q kernel --last 2>/dev/null | head -1 | awk '{print $1}' | sed 's/kernel-//')
        if [ -n "$latest_kernel" ] && [ "$latest_kernel" != "$current_kernel" ]; then
            return 0
        fi
    fi
    return 1
}

run_update() {
    log "INFO" "Iniciando actualización automática del sistema"
    send_telegram "🚀 Iniciando actualización automática del sistema..." "info"

    local packages_updated=0
    local update_success=true
    local sudo_prefix=""
    [ "$EUID" -ne 0 ] && sudo_prefix="sudo"

    if [ -f /etc/debian_version ]; then
        log "INFO" "Sistema detectado: Ubuntu/Debian (apt)"
        $sudo_prefix env DEBIAN_FRONTEND=noninteractive apt-get update -y >> "$LOG_FILE" 2>&1

        packages_updated=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo "0")

        if [ "$packages_updated" -gt 0 ]; then
            log "INFO" "Actualizando $packages_updated paquetes"
            $sudo_prefix env DEBIAN_FRONTEND=noninteractive apt-get upgrade -y >> "$LOG_FILE" 2>&1 || update_success=false
            $sudo_prefix env DEBIAN_FRONTEND=noninteractive apt-get autoremove -y >> "$LOG_FILE" 2>&1
            $sudo_prefix env DEBIAN_FRONTEND=noninteractive apt-get autoclean -y >> "$LOG_FILE" 2>&1
        fi
    elif [ -f /etc/redhat-release ]; then
        log "INFO" "Sistema detectado: Fedora/RHEL (dnf)"
        packages_updated=$(dnf check-update -q 2>/dev/null | awk 'NF>=3 {count++} END {print count+0}')

        if [ "$packages_updated" -gt 0 ]; then
            log "INFO" "Actualizando $packages_updated paquetes"
            $sudo_prefix dnf upgrade --refresh -y >> "$LOG_FILE" 2>&1 || update_success=false
            $sudo_prefix dnf autoremove -y >> "$LOG_FILE" 2>&1
        fi
    else
        log "ERROR" "Distribución no soportada (solo Ubuntu/Debian y Fedora/RHEL)"
        send_telegram "Distribución no soportada para actualización automática" "error"
        exit 1
    fi

    if [ "$update_success" = true ]; then
        if [ "$packages_updated" -gt 0 ]; then
            log "INFO" "Actualización completada: $packages_updated paquetes"
            send_telegram "📦 Actualización completada
• Paquetes actualizados: $packages_updated" "success"
        else
            log "INFO" "Sistema al día, sin cambios"
            send_telegram "📦 Sistema al día, sin cambios pendientes" "success"
        fi
    else
        log "ERROR" "Error durante la actualización"
        send_telegram "Error durante la actualización. Revisar ~/.local/state/dotfiles/updates.log" "error"
    fi

    if check_kernel_update; then
        log "INFO" "Kernel nuevo detectado, reiniciando en 60s..."
        send_telegram "🔄 Nuevo kernel instalado. Reiniciando en 60 segundos..." "reboot"
        sleep 60
        $sudo_prefix shutdown -r now 2>/dev/null || $sudo_prefix reboot
    fi
}

install_auto_update() {
    print_step "Configurando Actualizaciones Automáticas (Cron 04:00 AM)..."

    local script_path="$DOTFILES_DIR/scripts/cron-update.sh"
    if [ ! -f "$script_path" ]; then
        print_error "No se encontró $script_path"
        return 1
    fi

    chmod +x "$script_path"

    if ! command -v crontab &>/dev/null; then
        if [ "$OS_TYPE" == "debian" ]; then
            ensure_package "cron" "crontab"
        elif [ "$OS_TYPE" == "redhat" ]; then
            ensure_package "cronie" "crontab"
        fi
    fi

    if command -v crontab &>/dev/null; then
        (crontab -l 2>/dev/null | grep -v "cron-update.sh"; echo "0 4 * * * /bin/bash $script_path") | crontab -
        print_success "Cronjob configurado (04:00 AM diario)."
    else
        print_warning "crontab no disponible en este contenedor/entorno."
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    mkdir -p "$LOG_DIR"
    mkdir -p "$(dirname "$CONFIG_FILE")"
    run_update
    log "INFO" "Script de actualización finalizado"
fi
