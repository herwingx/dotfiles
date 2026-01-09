---

## 🐧 Consideraciones Especiales para WSL

Si ejecutas estos dotfiles en **Windows Subsystem for Linux (WSL)**, el instalador aplica configuraciones especiales automáticamente:

### ✅ Limpieza Automática del PATH

**Problema detectado**: En WSL, el `PATH` incluye rutas de Windows (`/mnt/c/*`) que pueden causar conflictos con binarios de Linux.

**Solución aplicada**: El instalador agrega automáticamente a tu `.bashrc`:

```bash
# WSL: Limpiar PATH de Windows (evitar conflictos con binarios .exe)
if grep -qi microsoft /proc/version 2>/dev/null; then
    # Filtrar rutas de /mnt/* del PATH
    NEW_PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '^/mnt/' | tr '\n' ':' | sed 's/:$//')
    export PATH="$NEW_PATH"
fi
```

### 🔍 ¿Por qué es necesario?

| Problema | Consecuencia | Solución |
| :------- | :----------- | :------- |
| `nvm4w` de Windows en PATH | `gemini` o `node` detectados en `/mnt/c/` no funcionan desde WSL | PATH filtrado, solo binarios de Linux |
| Extensiones MCP de Gemini fallan | Timeout o error: "Sin salida del comando" | Gemini instalado vía npm DENTRO de WSL |
| Git de Windows invocado | Problemas con line endings (CRLF vs LF) | Usa `git` de `/usr/bin/` exclusivamente |

### 🛡️ Mejores Prácticas en WSL

| Herramienta | ✅ Correcto (Linux) | ❌ Incorrecto (Windows) |
| :---------- | :------------------- | :----------------------- |
| **Node.js** | `nvm install node` en WSL | `nvm4w` desde PowerShell |
| **npm global** | `npm install -g` en WSL | `npm install -g` en CMD |
| **Git** | `/usr/bin/git` | `/mnt/c/Program Files/Git/bin/git` |
| **Docker** | Docker Desktop WSL 2 | Docker Toolbox |
| **SSH Keys** | Copiar con opción "9) SSH desde Windows" | Symlink a `/mnt/c/Users/.../.ssh` |

### 🚀 Instalación Recomendada en WSL

```bash
# 1. Clonar dotfiles
cd ~ && git clone https://github.com/tu-usuario/dotfiles.git

# 2. Ejecutar instalación completa
cd dotfiles && ./install.sh
# Selecciona opción 1 (TODO)

# 3. Instalar Node.js/npm DENTRO de WSL (si usas Gemini)
# La opción 11 (NVM + Node.js) ya lo hace, pero si lo saltaste:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install --lts

# 4. Si quieres Gemini CLI + extensiones MCP:
npm install -g @google/gemini-cli
# Luego ejecuta opción 20 (Settings)
```

> 💡 **Verificación**: Ejecuta `which node` y `which git`. Ambos deben apuntar a rutas en `/home/` o `/usr/bin/`, **nunca** a `/mnt/c/`.

