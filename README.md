# 🚀 Dotfiles v2.0

> **Tu entorno de desarrollo, automatizado** — Configuración unificada, idempotente y declarativa para Linux (Ubuntu, Fedora, Arch, WSL).

<!-- BADGES: Usa style=flat-square -->
[![Bash](https://img.shields.io/badge/Bash-5.0+-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Mise](https://img.shields.io/badge/Mise-Toolchain-blue?style=flat-square)](https://mise.jdx.dev/)
[![Linux](https://img.shields.io/badge/Linux-Compatible-FCC624?style=flat-square&logo=linux&logoColor=black)](https://www.linux.org/)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Age](https://img.shields.io/badge/Encryption-Age-blue?style=flat-square&logo=keybase&logoColor=white)](https://github.com/FiloSottile/age)

<p align="center">
  <img src="https://raw.githubusercontent.com/herwingx/dotfiles/main/docs/assets/banner.png" alt="Dotfiles Preview" width="800"/>
</p>

---

## 📑 Índice

- [🎯 ¿Qué es este proyecto?](#-qué-es-este-proyecto)
- [✨ Novedades v2.0](#-novedades-v20)
- [⚡ Prerequisitos OBLIGATORIOS](#-prerequisitos-obligatorios)
  - [🛤️ Elige tu Camino de Instalación](#️-elige-tu-camino-de-instalación)
  - [🪟 Flujo A: Windows + WSL](#-flujo-a-windows--wsl)
  - [🐧 Flujo B: Linux Nativo](#-flujo-b-linux-nativo)
- [🚀 Instalación (Menú Interactivo)](#-instalación)
- [🏗️ Arquitectura & Idempotencia](#️-arquitectura--idempotencia)
- [📦 Toolchain Declarativo (Mise)](#-toolchain-declarativo-mise)
- [🔐 Gestión de Secretos](#-gestión-de-secretos-envage)
- [🧩 Gestión de Extensiones](#-gestión-de-extensiones-vscodecursor)
- [📚 Documentación](#-documentación)
- [🛠️ Stack Tecnológico](#️-stack-tecnológico)
- [🗑️ Desinstalación](#️-desinstalación-total)
- [❓ FAQ y Troubleshooting](#-faq-y-troubleshooting)

---

## 🎯 ¿Qué es este proyecto?

**Dotfiles** es un sistema de ingeniería de plataforma personal. Transforma una instalación limpia de Linux en una estación de trabajo de alto rendimiento en minutos.

**Diferencias Clave:**

| Característica | Antes (v1) | **Ahora (v2.0)** |
| :--- | :--- | :--- |
| **Instalación** | Imperativa (Scripts manuales) | **Declarativa (Mise + TOML)** |
| **Ejecución** | Lenta, repetitiva | **Idempotente & Smart Updates** |
| **Tools** | Versiones hardcoded | **Versiones gestionadas (Node, Go, Rust)** |
| **UI** | Inconsistente | **Unificada (Cyberpunk Theme)** |

---

## ✨ Novedades v2.0

*   **Idempotencia Real**: Puedes ejecutar `./install.sh` mil veces; solo aplicará cambios si son necesarios.
*   **Mise (RTX)**: Reemplazamos instalaciones manuales de `node`, `go`, `rust`, `bat`, `lsd`, etc. por un único archivo de configuración `.mise.toml`.
*   **Smart Updates**: El sistema detecta si ya se actualizó en las últimas 24h para ahorrar tiempo (saltable con `--force`).
*   **Extension Manager**: Nuevo módulo para instalar/respaldar extensiones de VS Code/Cursor automáticamente.
*   **Secretos Híbridos**: Soporte para bóvedas locales (`.env.local.age`) que anulan la configuración del repo, ideal para forks.

---

## ⚡ Prerequisitos OBLIGATORIOS

> 🎯 **IMPORTANTE**: La configuración SSH es el fundamento. Sin ella, no podrás clonar ni contribuir.

### Requisitos del Sistema

| Requisito | Descripción |
| :--- | :--- |
| 🐧 **Sistema** | Linux (Debian, Ubuntu, Fedora, Arch) o WSL |
| 🌐 **Conexión** | Acceso a Internet |
| 🔐 **Git/GitHub** | Cuenta de GitHub |
| 🔑 **SSH Keys** | **OBLIGATORIO** - Ver guías abajo |

---

## 🛤️ Elige tu Camino de Instalación

| Tu Entorno | Flujo a Seguir |
|:-----------|:---------------|
| 🪟 **Windows con WSL** | [Flujo A: Windows + WSL](#-flujo-a-windows--wsl) → SSH se crea en Windows y se copia a WSL |
| 🐧 **Linux Nativo** | [Flujo B: Linux Nativo](#-flujo-b-linux-nativo) → SSH se crea directamente en Linux |

*(Ver README original para el detalle paso a paso de generación de SSH)*

---

## 🚀 Instalación

### 1. Clonar el Repositorio

```bash
git clone git@github.com:herwingx/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 2. Ejecutar el Instalador

```bash
chmod +x install.sh
./install.sh
```

### 3. Menú Interactivo v2.0

```text
  // 🚀 AUTOMATED DEPLOY
  +------------------------------------------------------------+
  [1 ] Full Install (System + Tools)
  +------------------------------------------------------------+

  // 📦 SYSTEM & TOOLCHAIN
  [2 ] Base System + Mise Tools        [3 ] Dev Tools Only (Docker, GH)
  [4 ] Toolchain Sync (mise install)   [5 ] Update System (Force)
  [6 ] Install Base Packages

  // ☁️ CONFIG & CLOUD
  [7 ] Configure Secrets               [8 ] Configure Rclone
  [9 ] SSH Keys Import                 [10] Install VSCode Extensions

  +------------------------------------------------------------+
  [0 ] EXIT
```

---

## 🏗️ Arquitectura & Idempotencia

El núcleo del sistema reside en `scripts/common.sh` y su función `ensure_package`.

**¿Cómo funciona?**
1.  Verifica si el binario ya existe en el `$PATH`.
2.  Si no, consulta la base de datos del gestor de paquetes (`dpkg`, `rpm`, `pacman`).
3.  Solo si ambas fallan, intenta instalar.

Esto hace que el instalador sea **extremadamente rápido** en ejecuciones subsecuentes.

---

## 📦 Toolchain Declarativo (Mise)

En lugar de scripts kilométricos instalando `tar.gz`, usamos **[Mise](https://mise.jdx.dev/)** (antes RTX).

Toda la configuración de herramientas está en `.mise.toml`:

```toml
[tools]
node = "lts"
go = "latest"
rust = "latest"
python = "latest"
lsd = "latest"
bat = "latest"
ripgrep = "latest"
oh-my-posh = "latest"
```

El script `scripts/toolchain.sh` se encarga de:
1. Instalar `mise` (si falta).
2. Ejecutar `mise install` (baja todas las herramientas en paralelo).
3. Configurarlas en tu shell.

---

## 🔐 Gestión de Secretos (.env.age)

Usamos **Age** para encriptación.

### Arquitectura de Bóvedas
1.  🥇 **`.env.local.age`**: Tu bóveda privada. Ignorada por Git.
2.  🥈 **`.env.age`**: Bóveda del repo (backup/ejemplo).

### Script de Gestión (`scripts/manage_secrets.sh`)
Interfaz TUI para editar tus secretos sin exponerlos en texto plano en el disco.

```bash
./scripts/manage_secrets.sh
```
*   **Edit Local**: Abre `nano`, editas, y al cerrar re-encripta automáticamente.
*   **View**: Muestra contenido temporalmente.

---

## 🧩 Gestión de Extensiones (VSCode/Cursor)

Nuevo módulo en `scripts/extensions.sh`.

### Instalación Automática
Detecta tu editor (`code`, `codium`, `cursor`) e instala las extensiones definidas en `.vscode-extensions`.

```bash
./install.sh  # Opción 10
# o directo:
./scripts/extensions.sh
```

### Backup de Extensiones
Si instalaste nuevas extensiones y quieres guardar la lista:

```bash
./scripts/extensions.sh --backup
```
Esto actualiza el archivo `.vscode-extensions` con tu configuración actual.

---

## 🛠️ Stack Tecnológico

| Categoría | Herramientas | Gestión |
| :--- | :--- | :--- |
| **Core** | Bash, Age, Git | `system.sh` |
| **Runtimes** | Node.js, Python, Go, Rust | **Mise** |
| **CLI Moderno** | lsd, bat, ripgrep, fzf | **Mise** |
| **Shell UI** | Oh My Posh | **Mise** + Config |
| **Infra** | Docker, Docker Compose | `dev-tools.sh` |
| **Cloud** | Rclone, GitHub CLI | `cloud.sh` |

---

## 🛠️ Developer Guide / Architecture

**Cómo funciona la Idempotencia**
El corazón de los dotfiles es la función `ensure_package` (en `scripts/common.sh`). Antes de ejecutar el gestor de paquetes de tu distro (`apt`, `dnf`, `zypper`, `apk`), el script verifica:
1. Si el binario de la herramienta ya está en tu `$PATH`.
2. Si el gestor de paquetes reporta la herramienta como ya instalada.
Solo si ambas comprobaciones fallan, se intenta instalar.

**Cómo extender el sistema**
1. **Nuevo Módulo:** Crea un archivo en `scripts/` (ej: `scripts/mi-modulo.sh`).
2. **Documentar:** Añade comentarios estilo Bashdoc en tus funciones (`@param`, `@sideeffects`).
3. **Incluir:** Añade el `source` de tu script en `install.sh`.
4. **Actualizar Menú:** Añade una nueva opción de ejecución al menú dentro de `install.sh`.

**Debugging Tips**
* Ejecuta `./install.sh` y fíjate en los prefijos `[OK]`, `[ERROR]`, `[!]` para saber exactamente dónde ocurrió el fallo.
* La mayoría de instalaciones de Node/Go fallarán silenciosamente si la descarga de `mise` es interrumpida. Revisa `.mise.toml` si una de estas herramientas falta.
* Puedes ejecutar los scripts individuales para testear de manera aislada: `bash scripts/cloud.sh`.

---

## 🗑️ Desinstalación Total

```bash
./uninstall.sh
```

*   **Full Destroy**: Elimina todo (configs, runtimes, docker).
*   **Soft Clean**: Solo configs (mantiene binarios grandes).

---

## ❓ FAQ y Troubleshooting

**P: ¿Por qué no veo los iconos en la terminal?**
R: Necesitas una **Nerd Font**. Recomendamos `Maple Mono NF` o `JetBrains Mono NF`.

**P: `mise: command not found`**
R: Reinicia tu terminal (`exec bash`) o asegúrate de que `~/.local/bin` está en tu PATH (el instalador lo hace, pero requiere recarga).

**P: Fallo al desencriptar secretos**
R: Asegúrate de tener la passphrase correcta. Si la perdiste y es tu propia bóveda, bórrala y crea una nueva con la opción **[17]** del instalador.

---

<p align="center">
  <sub>
    Made with ❤️ for the Linux community<br>
    <a href="https://github.com/herwingx/dotfiles">⭐ Star this repo</a>
  </sub>
</p>
