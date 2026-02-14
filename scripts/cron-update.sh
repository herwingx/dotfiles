#!/bin/bash
# ==========================================
# CRON-UPDATE - Actualizaciones automáticas del sistema
# ==========================================
# Script ejecutado por cron para actualizar el sistema
# y notificar via Telegram. Diseñado para servidores
# Proxmox (LXC/VMs) con horarios configurables.
# ==========================================

# --- CONFIGURACIÓN ---
# Usar directorios de usuario para evitar problemas de permisos
LOG_DIR="$HOME/.local/state/dotfiles"
LOG_FILE="$LOG_DIR/updates.log"
CONFIG_FILE="$HOME/.config/dotfiles/telegram.env"

# Usar $HOSTNAME con fallback para WSL donde hostname puede no estar
HOSTNAME="${HOSTNAME:-$(cat /etc/hostname 2>/dev/null || hostname 2>/dev/null || echo 'unknown')}"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Cargar variables de entorno del sistema
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# ─────────────────────────────────────────────────────────────
# Envía una notificación a Telegram.
#
# @param $1 - Mensaje a enviar
# @param $2 - Tipo: "success", "warning", "error", "info"
# ─────────────────────────────────────────────────────────────
send_telegram() {
    local MESSAGE="$1"
    local TYPE="${2:-info}"
    
    if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
        # Solo loguear warning si no está configurado, para no llenar el log
        # echo "[$DATE] [WARN] Telegram no configurado" >> "$LOG_FILE"
        return 1
    fi
    
    # Emojis según tipo
    case "$TYPE" in
        success) EMOJI="✅" ;;
        warning) EMOJI="⚠️" ;;
        error)   EMOJI="❌" ;;
        reboot)  EMOJI="🔄" ;;
        *)       EMOJI="ℹ️" ;;
    esac
    
    # Formatear mensaje con info del servidor
    local FULL_MESSAGE="$EMOJI <b>[$HOSTNAME]</b>
$MESSAGE

🕐 $DATE"

    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$FULL_MESSAGE" \
        -d parse_mode="HTML" > /dev/null 2>&1
}

# ─────────────────────────────────────────────────────────────
# Registra un mensaje en el log.
#
# @param $1 - Nivel: INFO, WARN, ERROR
# @param $2 - Mensaje
# ─────────────────────────────────────────────────────────────
log() {
    local LEVEL="$1"
    local MESSAGE="$2"
    echo "[$DATE] [$LEVEL] $MESSAGE" >> "$LOG_FILE"
}

# ─────────────────────────────────────────────────────────────
# Detecta si hay actualizaciones de kernel pendientes.
#
# @returns 0 si hay kernel nuevo, 1 si no
# ─────────────────────────────────────────────────────────────
check_kernel_update() {
    local CURRENT_KERNEL=$(uname -r)
    
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu: verificar si hay kernel más nuevo instalado
        local LATEST_KERNEL=$(ls -1 /boot/vmlinuz-* 2>/dev/null | sort -V | tail -1 | sed 's|/boot/vmlinuz-||')
        if [ -n "$LATEST_KERNEL" ] && [ "$LATEST_KERNEL" != "$CURRENT_KERNEL" ]; then
            return 0
        fi
    elif [ -f /etc/redhat-release ]; then
        # Fedora/RHEL: verificar kernel instalado vs actual
        local LATEST_KERNEL=$(rpm -q kernel --last 2>/dev/null | head -1 | awk '{print $1}' | sed 's/kernel-//')
        if [ -n "$LATEST_KERNEL" ] && [ "$LATEST_KERNEL" != "$CURRENT_KERNEL" ]; then
            return 0
        fi
    fi
    
    return 1
}

# ─────────────────────────────────────────────────────────────
# Ejecuta la actualización del sistema.
# Soporta: Debian/Ubuntu, Fedora/RHEL, Arch Linux
# ─────────────────────────────────────────────────────────────
run_update() {
    log "INFO" "Iniciando actualización del sistema"
    send_telegram "🚀 Iniciando actualización del sistema..." "info"
    
    local UPDATE_OUTPUT=""
    local PACKAGES_UPDATED=0
    local UPDATE_SUCCESS=true
    local SUDO_PREFIX=""

    # Detectar si necesitamos sudo (si no somos root)
    if [ "$EUID" -ne 0 ]; then
        SUDO_PREFIX="sudo"
    fi
    
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu
        log "INFO" "Sistema detectado: Debian/Ubuntu (apt)"
        
        $SUDO_PREFIX apt-get update -y >> "$LOG_FILE" 2>&1
        
        # Contar paquetes a actualizar
        PACKAGES_UPDATED=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo "0")
        
        if [ "$PACKAGES_UPDATED" -gt 0 ]; then
            log "INFO" "Actualizando $PACKAGES_UPDATED paquetes"
            
            # Configurar para no preguntar en actualizaciones
            export DEBIAN_FRONTEND=noninteractive
            $SUDO_PREFIX apt-get upgrade -y >> "$LOG_FILE" 2>&1 || UPDATE_SUCCESS=false
            $SUDO_PREFIX apt-get autoremove -y >> "$LOG_FILE" 2>&1
            $SUDO_PREFIX apt-get autoclean -y >> "$LOG_FILE" 2>&1
        fi
        
    elif [ -f /etc/redhat-release ]; then
        # Fedora/RHEL
        log "INFO" "Sistema detectado: Fedora/RHEL (dnf)"
        
        # Contar paquetes a actualizar
        PACKAGES_UPDATED=$(dnf check-update 2>/dev/null | grep -E "^\S+\.\S+" | wc -l || echo "0")
        
        if [ "$PACKAGES_UPDATED" -gt 0 ]; then
            log "INFO" "Actualizando $PACKAGES_UPDATED paquetes"
            $SUDO_PREFIX dnf upgrade --refresh -y >> "$LOG_FILE" 2>&1 || UPDATE_SUCCESS=false
            $SUDO_PREFIX dnf autoremove -y >> "$LOG_FILE" 2>&1
        fi
        
    elif [ -f /etc/arch-release ]; then
        # Arch Linux
        log "INFO" "Sistema detectado: Arch Linux (pacman)"
        
        $SUDO_PREFIX pacman -Syu --noconfirm >> "$LOG_FILE" 2>&1 || UPDATE_SUCCESS=false
        PACKAGES_UPDATED="N/A"
        
    else
        log "ERROR" "Sistema no soportado"
        send_telegram "Sistema no soportado para actualización automática" "error"
        exit 1
    fi
    
    # Reportar resultado
    if [ "$UPDATE_SUCCESS" = true ]; then
        if [ "$PACKAGES_UPDATED" -gt 0 ] || [ "$PACKAGES_UPDATED" = "N/A" ]; then
            log "INFO" "Actualización completada: $PACKAGES_UPDATED paquetes"
            send_telegram "📦 Actualización completada
• Paquetes actualizados: $PACKAGES_UPDATED" "success"
        else
            log "INFO" "Sistema ya actualizado, sin cambios"
            send_telegram "📦 Sistema ya actualizado, sin cambios pendientes" "success"
        fi
    else
        log "ERROR" "Error durante la actualización"
        send_telegram "Error durante la actualización. Revisar logs." "error"
    fi
    
    # Verificar si se necesita reinicio por kernel
    if check_kernel_update; then
        log "INFO" "Kernel actualizado detectado, reinicio programado"
        send_telegram "🔄 Kernel actualizado detectado.
Reiniciando en 60 segundos..." "reboot"
        
        # Esperar 60 segundos y reiniciar
        sleep 60
        log "INFO" "Ejecutando reinicio..."
        
        # Verificar si estamos en un container LXC (no se puede reiniciar normalmente)
        if [ -f /proc/1/environ ] && grep -q "container=lxc" /proc/1/environ 2>/dev/null; then
            log "INFO" "LXC detectado, solicitando reinicio al host"
            # En LXC el reinicio es manejado por el host
            $SUDO_PREFIX reboot
        else
            # VM o bare metal
            $SUDO_PREFIX shutdown -r now
        fi
    fi
}

# ─────────────────────────────────────────────────────────────
# Configura el cron job para actualizaciones automáticas
# ─────────────────────────────────────────────────────────────
install_auto_update() {
    print_step "Configurando Actualizaciones Automáticas (Cron)..."
    
    local SCRIPT_PATH="$DOTFILES_DIR/scripts/cron-update.sh"
    
    if [ ! -f "$SCRIPT_PATH" ]; then
        print_error "No se encontró el script de actualización en $SCRIPT_PATH"
        return 1
    fi
    
    chmod +x "$SCRIPT_PATH"
    
    # Crear entrada en crontab (diario a las 04:00 AM)
    # Evitar duplicados eliminando entradas previas que contengan el nombre del script
    (crontab -l 2>/dev/null | grep -v "cron-update.sh"; echo "0 4 * * * /bin/bash $SCRIPT_PATH") | crontab -
    
    print_success "Cron job configurado (Ejecución: 04:00 AM diario)"
}

# ─────────────────────────────────────────────────────────────
# MAIN (Solo si se ejecuta directamente)
# ─────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Crear directorio de logs y config si no existe
    mkdir -p "$LOG_DIR"
    mkdir -p "$(dirname "$CONFIG_FILE")"

    # Ejecutar actualización
    run_update

    log "INFO" "Script de actualización finalizado"
fi
