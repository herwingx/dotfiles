#!/bin/bash
# ==============================================================================
# GESTOR DE SECRETOS (.env.age)
# ==============================================================================
# Este script facilita la edición del archivo encriptado .env.age
# Uso: ./manage_secrets.sh {edit|view|add-rclone}

DOTFILES_DIR=$(dirname "$(dirname "$(readlink -f "$0")")")
SECRETS_FILE="$DOTFILES_DIR/.env.age"
TEMP_FILE="$DOTFILES_DIR/.env.tmp"

# Verificar dependencias
if ! command -v age &> /dev/null; then
    echo "Error: 'age' no está instalado. Ejecuta: sudo apt install age"
    exit 1
fi

# Función para mostrar menú interactivo
show_menu() {
    clear
    echo "=========================================="
    echo "🔐 GESTOR DE SECRETOS (.env.age)"
    echo "=========================================="
    echo "1) ✏️  Editar secretos (desencriptar -> editar -> encriptar)"
    echo "2) 👁️  Ver secretos (solo lectura)"
    echo "0) ❌ Salir"
    echo "=========================================="
    read -p "Selecciona una opción: " choice

    case $choice in
        1) action_edit ;;
        2) action_view ;;
        0) exit 0 ;;
        *) echo "Opción inválida"; sleep 1; show_menu ;;
    esac
}

# Acciones encapsuladas
action_edit() {
    # 1. Desencriptar
    if [ -f "$SECRETS_FILE" ]; then
        echo ">>> Desencriptando $SECRETS_FILE..."
        # Intentar desencriptar, si falla age devolverá error (normalmente pide pass)
        age --decrypt "$SECRETS_FILE" > "$TEMP_FILE"
        if [ $? -ne 0 ]; then
            echo "Error: Falló la desencriptación o contraseña incorrecta."
            rm -f "$TEMP_FILE"
            exit 1
        fi
    else
        echo ">>> Creando nuevo archivo de secretos..."
        touch "$TEMP_FILE"
    fi

    # 2. Editar
    EDITOR=${EDITOR:-nano}
    $EDITOR "$TEMP_FILE"

    # 3. Encriptar
    echo ">>> Encriptando cambios..."
    echo "⚠️  Nota: Se te pedirá una passphrase nueva o la misma para confirmar."
    age --passphrase --output "$SECRETS_FILE" "$TEMP_FILE"
    
    if [ $? -eq 0 ]; then
        rm "$TEMP_FILE"
        echo ">>> ✅ ¡Archivo actualizado y encriptado exitosamente!"
    else
        echo ">>> ❌ Error al encriptar. Tu archivo desencriptado sigue en $TEMP_FILE por seguridad."
    fi
}

action_view() {
    if [ -f "$SECRETS_FILE" ]; then
        echo ">>> Mostrando contenido (requiere passphrase)..."
        age --decrypt "$SECRETS_FILE"
        echo ""
        read -p "Presiona Enter para continuar..."
    else
        echo "❌ El archivo $SECRETS_FILE no existe."
    fi
}



# Lógica principal: Argumentos vs Menú
if [ -z "$1" ]; then
    # Si no hay argumentos, mostrar menú
    while true; do show_menu; done
else
    # Si hay argumentos, mantener compatibilidad CLI
    case "$1" in
        edit) action_edit ;;
        view) action_view ;;
        *) echo "Uso: $0 [edit|view]"; exit 1 ;;
    esac
fi
