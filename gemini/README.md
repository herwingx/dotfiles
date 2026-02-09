# 🤖 Gemini AI - Configuración Antigravity

> **Potencia tu asistente de IA** — Reglas de desarrollo, workflows automatizados y extensiones MCP para Gemini.

[![MCP](https://img.shields.io/badge/MCP-Model_Context_Protocol-blue?style=flat-square)](https://modelcontextprotocol.io/)
[![Gemini](https://img.shields.io/badge/Gemini-CLI-orange?style=flat-square)](https://ai.google.dev/)

---

## 📑 Índice

- [🎯 ¿Qué es Antigravity?](#-qué-es-antigravity)
- [✨ ¿Por qué usar este framework?](#-por-qué-usar-este-framework)
- [🚀 Inicio Rápido](#-inicio-rápido)
- [📁 Estructura de Archivos](#-estructura-de-archivos)
- [📜 Reglas de Desarrollo (GEMINI.md)](#-reglas-de-desarrollo-geminimd)
- [🔄 Workflows Disponibles](#-workflows-disponibles)
- [🔌 Extensiones MCP](#-extensiones-mcp)
- [⚙️ Configuración Avanzada (settings.json)](#️-configuración-avanzada-settingsjson)
- [🔐 Seguridad](#-seguridad)
- [📚 Recursos Adicionales](#-recursos-adicionales)

---

## 🎯 ¿Qué es Antigravity?

**Antigravity** es el IDE de codificación agéntica avanzada de Google (**Google Advanced Agentic Coding IDE**), diseñado para trabajar en par con desarrolladores mediante IA.

Este repositorio proporciona un framework de configuración que es compatible tanto con el **IDE Antigravity** como con la **Gemini CLI**, ya que ambas herramientas comparten la misma ruta de instalación y archivos de configuración (`~/.gemini/`).

---

## ✨ ¿Por qué usar este framework?

El framework combina tres pilares fundamentales:

### 1. 📜 **Reglas de Desarrollo Estandarizadas**

Protocolos definidos en `GEMINI.md` para **Ejecución Inmediata**:
- ✅ Conventional Commits automáticos
- ✅ Git Flow con protección de `main`
- ✅ Clean Code y nomenclatura consistente
- ✅ Versionado Semántico (SemVer 2.0.0)

### 2. ⚡ **Workflows Automatizados**

Comandos slash para eliminar tareas repetitivas:
- `/commit` → Crear commits siguiendo Conventional Commits
- `/crear-pr` → Generar Pull Requests con descripción completa
- `/release` → Publicar releases con tags y changelog automático
- Y 5 workflows más...

### 3. 🔌 **Extensiones MCP (Model Context Protocol)**

Servidores que amplían las capacidades de Gemini:
- 🌐 **Web Search**: Búsqueda en internet para documentación y soluciones actualizadas.
- 🐙 **GitHub**: Gestión de repos, PRs, issues desde la IA
- 💻 **Terminal**: Ejecución de comandos y diagnósticos del sistema.
- 📄 **Filesystem**: Gestión inteligente de archivos y directorios.

### 📊 Tabla Comparativa

| Sin Framework | Con Framework Antigravity |
|:--------------|:--------------------------|
| Commits inconsistentes | Conventional Commits automático |
| PRs sin contexto | Descripción generada de cambios |
| Buscar comandos manualmente | `/commit`, `/release` al instante |
| Agente "Conversacional" | Agente "Ejecutor" (Output First) |
| Configuración manual | Reglas optimizadas para velocidad |

---

## 🚀 Inicio Rápido

### Método Automático (Recomendado)

Desde el instalador principal de dotfiles:

```bash
cd ~/dotfiles
./install.sh

# Selecciona una de estas opciones:
# [4 ] Solo Antigravity AI (Reglas + Workflows)
# [14] Instalar Reglas IA (GEMINI.md)
# [15] Instalar Comandos Slash (/commit...)
```

**¿Qué instala?**
- ✅ Reglas `GEMINI.md` optimizadas en `~/.gemini/`
- ✅ Workflows en `~/.gemini/antigravity/global_workflows/`
- ✅ Extensiones MCP configuradas por defecto

### Verificar Instalación

```bash
# 1. Verificar que las reglas existen
ls ~/.gemini/GEMINI.md

# 2. Verificar workflows instalados
ls ~/.gemini/antigravity/global_workflows/
```

---

## 📁 Estructura de Archivos

```
gemini/
├── GEMINI.md           # 📜 Protocolo de Acción Inmediata
│                       #    • Output First (Código directo)
│                       #    • Git Flow & Conventional Commits
│                       #    • Stack Preferido (gh CLI)
│                       #    • Checklist de Auto-Corrección
│
├── settings.json       # ⚙️  Configuración del Agente
│                       #    • MCP Servers
│                       #    • Preferencias de UI
│
└── workflows/          # 🔄 Workflows automatizados (comandos slash)
    ├── commit.md       # • /commit - Conventional Commits automático
    ├── crear-pr.md     # • /crear-pr - Crear Pull Request
    ├── crear-readme.md # • /crear-readme - Generar README profesional
    ├── deshacer-commit.md # • /deshacer-commit - Soft reset HEAD~1
    ├── fusionar-pr.md  # • /fusionar-pr - Squash & Merge + cleanup
    ├── hotfix.md       # • /hotfix - Crear rama de hotfix
    ├── limpiar-ramas.md # • /limpiar-ramas - Eliminar ramas fusionadas
    ├── nueva-feature.md # • /nueva-feature - Branch desde main actualizado
    ├── publicar.md     # • /publicar - Push al remoto
    ├── release.md      # • /release - Tag + GitHub Release
    ├── revisar-codigo.md # • /revisar-codigo - Code Review local/PR
    └── sync-main.md    # • /sync-main - Rebase con main
```

---

## 📜 Reglas de Desarrollo (GEMINI.md)

El archivo `GEMINI.md` es el **protocolo de actuación** que el agente debe seguir. Ha sido optimizado para **velocidad y eficiencia**.

### Directivas Principales

| Regla | Descripción |
|:------|:------------|
| 🚀 **Acción Inmediata** | Minimizar conversación. Entregar código/comandos primero. |
| 🔀 **Git Flow** | • Nunca commit directo a `main`<br>• Ramas efímeras (`feat/`, `fix/`)<br>• PRs obligatorios |
| 📝 **Conventional Commits** | • Formato: `type(scope): descripción`<br>• `feat`, `fix`, `docs`, `chore`<br>• Español imperativo |
| 🛠️ **Automatización** | • Preferir `gh` CLI sobre navegador<br>• `gh pr create --fill`<br>• `gh pr merge --squash` |
| 🧹 **Código Limpio** | • Sin logs basura<br>• Naming convention en Inglés<br>• Docs solo en exports públicos |

### Ejemplo de Workflow del Agente

```text
Usuario: "Sube estos cambios"

Agente (Ejecutando protocolo):
1. Detecta estado del repo (git status)
2. Crea commit convencional: `feat(auth): login flow`
3. Push a rama: `git push -u origin feat/auth`
4. Crea PR: `gh pr create --fill`
```

---

## 🔄 Workflows Disponibles

Los workflows se instalan en `~/.gemini/antigravity/global_workflows/` y se invocan con comandos slash.

> 🖥️ **Diseño "Terminal-First"**: Todos los workflows están optimizados para funcionar en entornos **Headless** (servidores SSH, WSL sin GUI). Utilizan exclusivamente `gh` CLI.

### Tabla de Comandos Rápidos

| Comando | Acción del Agente |
|:--------|:------------------|
| `/commit` | Genera mensaje convencional y hace commit |
| `/crear-pr` | Crea PR usando `gh` CLI automáticamente |
| `/publicar` | Empuja cambios al remoto (`git push`) |
| `/sync-main` | Trae cambios de main y hace rebase |
| `/release` | Crea tag y release en GitHub |

---

## 🔌 Extensiones MCP

### ¿Qué es MCP?

**Model Context Protocol (MCP)** permite al agente conectar con herramientas externas. Esto le da "superpoderes" más allá de generar texto.

### Servidores Integrados

| Extensión | Uso del Agente |
|:----------|:---------------|
| 💻 **Terminal** | Ejecutar comandos, crear archivos, instalar deps. |
| 🐙 **GitHub** | Leer issues, comentar en PRs, revisar código. |
| 🌐 **Web Search** | Buscar documentación actualizada, soluciones a errores. |
| 📄 **Filesystem** | Leer y modificar el codebase de forma segura. |

---

## ⚙️ Configuración Avanzada (settings.json)

El archivo `settings.json` define las capacidades del agente.

```json
{
  "mcpServers": {
    "github": {
      "command": "docker", // O npx
      "args": ["..."],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    }
  },
  "ui": {
    "theme": "github"
  }
}
```

---

## 🔐 Seguridad

El framework sigue el principio de **privacidad y seguridad**:

1. **Tokens Encriptados**: Usa `.env.age` para guardar tokens sensibles.
2. **Ejecución Local**: Los comandos corren en tu máquina.
3. **Revisión Humana**: El agente propone, tú apruebas (especialmente comandos destructivos).

---

## 📚 Recursos Adicionales

- 📘 [Model Context Protocol (MCP)](https://modelcontextprotocol.io/)
- 🔗 [Conventional Commits](https://www.conventionalcommits.org/)
- 🐙 [GitHub CLI Manual](https://cli.github.com/manual/)

---

<p align="center">
  <sub>
    Configuración optimizada para desarrollo de alta velocidad con IA<br>
    <a href="https://github.com/herwingx/dotfiles">⭐ Star este repo</a> si te resultó útil
  </sub>
</p>
