# 🚀 Dotfiles - herwingx

Configuración personal para sincronizar entorno de desarrollo en múltiples máquinas Linux (Ubuntu, Fedora, Arch, WSL).

## ⚡ Instalación Rápida

```bash
# Clonar (HTTPS, no necesita SSH)
git clone https://github.com/herwingx/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Ejecutar instalador
chmod +x install.sh
./install.sh
```

## 📦 ¿Qué incluye?

### Sistema Base (Opción 6)
| Paquete | Descripción |
|:--------|:------------|
| `git`, `curl`, `wget` | Esenciales |
| `vim`, `tmux` | Editor y multiplexor |
| `htop`, `btop` | Monitores de sistema |
| `fzf` | Fuzzy finder |
| `ranger`, `mc` | File managers de terminal |
| `neofetch`, `tree` | Utilidades |

### Dev Tools (Opción 3)
| Herramienta | Descripción |
|:------------|:------------|
| GitHub CLI (`gh`) | Con auth automático desde Bitwarden |
| NVM + Node.js LTS | Manejo de versiones de Node |
| npm packages | `@bitwarden/cli`, `@anthropic-ai/claude-code` |
| Docker + Compose | Contenedores |
| Terminal Tools | `lsd`, `lazydocker`, `ctop`, `gping` |

### Antigravity (Opción 4)
Configuración de Gemini AI:
- `GEMINI.md` - Reglas globales de desarrollo
- Workflows: `/commit`, `/publicar`, `/sync-main`, `/crear-pr`, `/nueva-feature`, `/release`, `/limpiar-ramas`

## 🔐 Autenticación Automática

El script usa **Bitwarden CLI** para obtener automáticamente:
- Tu token de GitHub (desde la nota "Github Personal Access Token")

Solo necesitas ingresar:
1. 🔐 Master Password de Bitwarden
2. 📱 Código 2FA (si tienes habilitado)

## 🖥️ WSL (Windows Subsystem for Linux)

Si usas WSL, puedes copiar tus llaves SSH desde Windows:

```bash
./install.sh
# Selecciona opción 10: Copiar SSH desde Windows
```

Detecta automáticamente tu usuario de Windows.

## 📋 Menú Completo

```
╔════════════════════════════════════════════════════════════════╗
║            🚀 DOTFILES INSTALLER - herwingx 🚀                 ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║  INSTALACIÓN COMPLETA                                          ║
║   1) Instalar TODO (sistema + dev tools + antigravity)         ║
║   2) Solo Sistema (update + paquetes, aliases, git, ssh)       ║
║   3) Solo Dev Tools (gh, nvm, docker, terminal tools)          ║
║   4) Solo Antigravity (reglas + workflows)                     ║
║                                                                ║
║  SISTEMA (individual)                                          ║
║   5) Actualizar sistema (apt/dnf upgrade)                      ║
║   6) Paquetes (git, fzf, tmux, ranger, mc, htop, btop...)      ║
║   7) Bash Aliases                                              ║
║   8) Git Config                                                ║
║   9) SSH Keys (importar desde GitHub)                          ║
║  10) Copiar SSH desde Windows (solo WSL)                       ║
║                                                                ║
║  DEV TOOLS (individual)                                        ║
║  11) GitHub CLI (gh + auth)                                    ║
║  12) NVM + Node.js LTS                                         ║
║  13) npm packages (bitwarden-cli, claude-code)                 ║
║  14) Docker + Docker Compose                                   ║
║  15) Terminal Tools (lsd, lazydocker, ctop, gping)             ║
║                                                                ║
║  ANTIGRAVITY (individual)                                      ║
║  16) Solo Reglas (GEMINI.md)                                   ║
║  17) Solo Workflows (/commit, /publicar, etc.)                 ║
║                                                                ║
║   0) Salir                                                     ║
╚════════════════════════════════════════════════════════════════╝
```

## 🎨 Aliases Incluidos

### LSD (ls moderno)
```bash
ls   → lsd
ll   → lsd -la
lt   → lsd --tree
```

### Git
```bash
gs   → git status
ga   → git add
gc   → git commit -m
gp   → git push
gl   → git pull
glog → git log --oneline --graph
```

### Docker
```bash
d    → docker
dc   → docker compose
dps  → docker ps
dlog → docker logs -f
```

### Sistema
```bash
update → actualiza el sistema (detecta apt/dnf/pacman)
c      → clear
..     → cd ..
myip   → muestra IP pública
```

## 🔄 Sincronizar Cambios

Después de hacer cambios en cualquier máquina:

```bash
# En la máquina donde hiciste cambios
cd ~/dotfiles
git add . && git commit -m "feat: descripción" && git push

# En otras máquinas
sync-dotfiles   # Alias incluido
```

## 📁 Estructura

```
dotfiles/
├── install.sh          # Script principal
├── .bash_aliases       # Aliases de terminal
├── .gitconfig          # Configuración de Git
├── GEMINI.md           # Reglas de Antigravity
├── global_workflows/   # Workflows de Antigravity
│   ├── commit.md
│   ├── crear-pr.md
│   ├── limpiar-ramas.md
│   ├── nueva-feature.md
│   ├── publicar.md
│   ├── release.md
│   └── sync-main.md
└── README.md           # Este archivo
```

## 📄 Licencia

MIT - Usa y modifica libremente.

---

Made with ❤️ by [herwingx](https://github.com/herwingx)
