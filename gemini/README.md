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

Protocolos definidos en `GEMINI.md`:
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
- 🌐 **Chrome DevTools**: Debugging e inspección en navegadores
- 🐙 **GitHub**: Gestión de repos, PRs, issues desde la IA
- 🐘 **Postgres**: Ejecución de queries SQL y gestión de schemas
- 🍌 **Nanobanana**: Utilidades de productividad

### 📊 Tabla Comparativa

| Sin Framework | Con Framework Antigravity |
|:--------------|:--------------------------|
| Commits inconsistentes | Conventional Commits automático |
| PRs sin contexto | Descripción generada de cambios |
| Buscar comandos manualmente | `/commit`, `/release` al instante |
| Configuración manual de extensiones | MCP servers preconfigurados |
| Tokens expuestos en código | Age encryption + `.env.age` |

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
- ✅ Reglas `GEMINI.md` en `~/.gemini/`
- ✅ Workflows en `~/.gemini/antigravity/global_workflows/`
- ✅ Configuración `settings.json` con MCP servers
- ✅ Token de GitHub exportado automáticamente
- ✅ Extensiones MCP instaladas (si tienes Node.js)

### Verificar Instalación

```bash
# 1. Verificar que las reglas existen
ls ~/.gemini/GEMINI.md

# 2. Verificar workflows instalados
ls ~/.gemini/antigravity/global_workflows/

# 3. Verificar extensiones MCP (requiere Gemini CLI)
gemini extensions list

# 4. Verificar token de GitHub
echo $GITHUB_PERSONAL_ACCESS_TOKEN  # Debe mostrar tu token
```

---

## 📁 Estructura de Archivos

```
gemini/
├── GEMINI.md           # 📜 Reglas globales de desarrollo
│                       #    • Conventional Commits
│                       #    • Git Flow (feat/, fix/, hotfix/)
│                       #    • Clean Code (sin console.log, nomenclatura)
│                       #    • Versionado Semántico
│
├── settings.json       # ⚙️  Configuración de Gemini CLI
│                       #    • MCP Servers (GitHub, Chrome, Postgres)
│                       #    • Autenticación OAuth
│                       #    • Tema UI (GitHub claro)
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

El archivo `GEMINI.md` es el **protocolo completo** que Gemini debe seguir en todos tus proyectos.

### Secciones Principales

| Categoría | Reglas Incluidas |
|:----------|:-----------------|
| 🔀 **Git Flow** | • Nunca commit directo a `main`<br>• Nomenclatura de ramas (`feat/`, `fix/`, `hotfix/`)<br>• Squash & Merge obligatorio |
| 📝 **Conventional Commits** | • Formato: `type(scope): descripción`<br>• Breaking changes: `type!`<br>• Tipos: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `chore`, `ci` |
| 🏷️ **Versionado Semántico** | • SemVer 2.0.0 (MAJOR.MINOR.PATCH)<br>• `feat` → Minor<br>• `fix`/`perf` → Patch<br>• `type!` → Major |
| 🌐 **Idioma** | • Código, variables, funciones: **Inglés**<br>• Commits, docs, PRs: **Español** |
| 📖 **Documentación** | • DocBlocks obligatorios (JSDoc/TSDoc)<br>• "The Why, Not The What"<br>• Better Comments (`// !`, `// ?`, `// TODO`) |
| 🧹 **Código Limpio** | • Sin `console.log`, `debugger`, `alert()`<br>• Sin código comentado<br>• Variables descriptivas (evitar `data`, `info`, `temp`) |

### Ejemplo de Conventional Commit

```bash
# ✅ Correcto: Nueva funcionalidad
feat(auth): implementar login con Google OAuth

# ✅ Correcto: Corrección de bug
fix(navbar): corregir solapamiento en móviles

# ✅ Correcto: Breaking change (bump MAJOR)
feat(api)!: cambiar formato de respuesta de usuarios

# ❌ Incorrecto: No sigue el formato
added new feature for users
```

### Impacto en Versión

| Commit | Versión Anterior | Versión Nueva | Cambio |
|:-------|:-----------------|:--------------|:-------|
| `feat(users): añadir avatar` | 1.0.0 | 1.**1**.0 | Minor |
| `fix(login): validar email` | 1.0.0 | 1.0.**1** | Patch |
| `feat(api)!: nuevo formato` | 1.0.0 | **2**.0.0 | Major |

---

## 🔄 Workflows Disponibles

Los workflows se instalan en `~/.gemini/antigravity/global_workflows/` y se invocan con comandos slash.

> 🖥️ **Diseño "Terminal-First"**: Todos los workflows están optimizados para funcionar en entornos **Headless** (servidores SSH, WSL sin GUI). Utilizan exclusivamente `gh` CLI en modo texto, evitando abrir navegadores web.

### Tabla Completa de Workflows

| Comando | Descripción | Caso de Uso | Auto-Run |
|:--------|:------------|:------------|:---------|
| `/commit` | Crear commits con Conventional Commits | "Crea un commit para los cambios en auth" | ❌ |
| `/crear-pr` | Crear Pull Request en GitHub | "Crea un PR para feat/login" | ❌ |
| `/nueva-feature` | Iniciar desarrollo de feature | "Inicia feature para módulo de pagos" | ❌ |
| `/publicar` | Publicar rama al remoto | "Publica la rama actual" | ✅ |
| `/release` | Crear release con tag y changelog | "Crea release v1.2.0" | ❌ |
| `/sync-main` | Rebase con main | "Sincroniza esta rama con main" | ❌ |
| `/crear-readme` | Generar README.md profesional | "Crea un README para este proyecto" | ❌ |
| `/limpiar-ramas` | Eliminar ramas fusionadas | "Limpia ramas que ya están en main" | ❌ |
| `/deshacer-commit` | Soft reset HEAD~1 | "Deshaz el último commit pero mantén cambios" | ✅ |
| `/fusionar-pr` | Squash & Merge + cleanup | "Fusiona el PR actual" | ❌ |
| `/hotfix` | Crear rama de hotfix | "Inicia hotfix para error crítico" | ❌ |
| `/revisar-codigo` | Code Review local o de PR | "Revisa el código de feat/login" | ❌ |

### Ejemplo de Uso Real

```bash
# En una conversación con Gemini (IDE o CLI):

Usuario: /crear-pr

Gemini: [Ejecuta workflow crear-pr.md]
        
        ✓ Verificando que estás en una rama de trabajo...
        ✓ Actualizando main...
        ✓ Analizando commits de la rama...
        ✓ Generando descripción del PR...
        
        Descripción generada:
        ---
        ## 🎯 Objetivo
        Implementar autenticación con Google OAuth
        
        ## 📝 Cambios
        - Agregar botón "Login with Google"
        - Integrar SDK de Google Identity
        - Guardar tokens en localStorage
        
        ## ✅ Testing
        - Probado en Chrome, Firefox, Safari
        - Flow de login completo funcionando
        ---
        
        ¿Crear PR con esta descripción? [Y/n]
```

### Crear Workflows Personalizados

Puedes crear tus propios workflows:

1. Crear archivo en `~/.gemini/antigravity/global_workflows/mi-workflow.md`
2. Usar este formato:

```markdown
---
description: Descripción breve (aparece en `/help`)
---

# Mi Workflow Personalizado

## Pasos

1. Hacer algo importante
   ```bash
   git status
   ```

// turbo
2. Este paso se ejecuta automáticamente (SafeToAutoRun=true)
   ```bash
   git fetch origin
   ```

3. Paso final que requiere confirmación
   ```bash
   git push
   ```
```

> 💡 **Tip**: Usa `// turbo` antes de pasos **seguros** (lecturas, fetch, status) para auto-ejecución.

---

## 🔌 Extensiones MCP

### ¿Qué es MCP?

**Model Context Protocol (MCP)** es un estándar abierto desarrollado por Anthropic que permite a los LLMs (como Gemini) interactuar con herramientas externas, APIs y servicios de forma estandarizada.

**Beneficios**:
- ✅ Gemini puede leer/escribir en GitHub sin salir del chat
- ✅ Debugging de navegadores desde la IA
- ✅ Ejecutar queries SQL en bases de datos
- ✅ Extensible con cualquier herramienta que implemente el protocolo

### Servidores MCP Instalados

| Extensión | Repositorio | Capacidades | Requisitos |
|:----------|:------------|:------------|:-----------|
| 🌐 **Chrome DevTools** | [ChromeDevTools/chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) | • Inspección de elementos<br>• Control de pestañas<br>• Debugging JavaScript<br>• Screenshots | Docker |
| 🐙 **GitHub** | [github/github-mcp-server](https://github.com/github/github-mcp-server) | • Gestión de repos<br>• Crear issues y PRs<br>• Búsqueda de código<br>• Revisión de commits | Docker + `GH_TOKEN` |
| 🐘 **Postgres** | [gemini-cli-extensions/postgres](https://github.com/gemini-cli-extensions/postgres) | • Ejecución de queries SQL<br>• Inspección de schemas<br>• Gestión de tablas e índices | Node.js + npx |
| 🍌 **Nanobanana** | [gemini-cli-extensions/nanobanana](https://github.com/gemini-cli-extensions/nanobanana) | • Utilidades de sistema<br>• Productividad adicional | Node.js + npx |

### Gestión de Extensiones

```bash
# Listar extensiones instaladas
gemini extensions list

# Instalar una nueva extensión
gemini extensions install "https://github.com/usuario/repo-mcp"

# Actualizar todas las extensiones
gemini extensions update --all

# Eliminar una extensión
gemini extensions remove nombre-extension

# Ver logs de una extensión (debugging)
gemini extensions logs nombre-extension
```

### Ejemplo de Uso

```bash
# En una conversación con Gemini:

Usuario: "¿Cuántos PRs abiertos tengo en el repo 'dotfiles'?"

Gemini: [Usa extensión MCP de GitHub]
        
        Consultando GitHub...
        
        Tienes 2 PRs abiertos en herwingx/dotfiles:
        
        1. feat/ssh-guide (#12)
           - Creado hace 2 horas
           - 5 commits
           - Sin conflictos
        
        2. docs/improve-readme (#11)
           - Creado hace 1 día
           - 3 commits
           - Requiere rebase con main
```

---

## ⚙️ Configuración Avanzada (settings.json)

El archivo `settings.json` configura el comportamiento de Gemini CLI y el IDE Antigravity.

### Secciones del Archivo

```json
{
  "mcpServers": {
    // Configuración de extensiones MCP
  },
  "security": {
    "auth": {
      "type": "oauth_personal"  // Tipo de autenticación
    }
  },
  "general": {
    "features": {
      "preview": {
        "vimMode": false  // Desactivar modo Vim
      }
    }
  },
  "context": {
    "gitignore": {
      "respect": false  // Para dotfiles, no respetar .gitignore
    }
  },
  "ui": {
    "theme": "github"  // Tema visual
  }
}
```

### Configurar un Servidor MCP (Ejemplo: GitHub)

```json
{
  "mcpServers": {
    "github": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-e",
        "GITHUB_PERSONAL_ACCESS_TOKEN",
        "ghcr.io/github/github-mcp-server:latest"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    }
  }
}
```

**Notas importantes**:
- La variable `${GITHUB_PERSONAL_ACCESS_TOKEN}` se reemplaza automáticamente
- El token se exporta en `~/.bashrc` durante la instalación
- Los servidores MCP pueden usar Docker (`command: "docker"`) o npx (`command: "npx"`)

### Personalizar el Tema

Temas disponibles:
- `github` (claro, predeterminado)
- `monokai` (oscuro)
- `solarized-light`
- `solarized-dark`

```json
{
  "ui": {
    "theme": "monokai"
  }
}
```

---

## 🔐 Seguridad

### Gestión del Token de GitHub

El token de GitHub (`GH_TOKEN`) se maneja de forma segura:

1. **Almacenamiento**: Encriptado en `.env.age` con Age encryption
2. **Extracción**: Solo en runtime durante la instalación
3. **Persistencia**: Exportado en `~/.bashrc` como `GITHUB_PERSONAL_ACCESS_TOKEN`
4. **Uso**: Disponible para `gh` CLI, extensiones MCP y workflows

### Permisos Requeridos (Scopes)

Para que las extensiones MCP funcionen correctamente, el token de GitHub debe tener estos scopes:

| Scope | Propósito | ¿Por qué es necesario? |
|:------|:----------|:-----------------------|
| `repo` | Acceso completo a repositorios | Crear PRs, issues, push, pull |
| `workflow` | Gestión de GitHub Actions | Disparar workflows, ver logs |
| `read:org` | Leer información de organizaciones | Listar repos de tu organización |
| `read:user` | Leer perfil de usuario | Obtener tu info de perfil |

### Crear Token de GitHub

1. Ve a: [https://github.com/settings/tokens](https://github.com/settings/tokens)
2. Click en **"Generate new token"** → **"Classic"**
3. Nombre: `Dotfiles - Gemini MCP`
4. Selecciona los scopes: `repo`, `workflow`, `read:org`, `read:user`
5. Click en **"Generate token"**
6. **Copia el token** (solo se muestra una vez)
7. Guárdalo en `.env.age`:

```bash
# Editar secretos
./scripts/manage_secrets.sh
# Selecciona [1] Editar
# Agrega la línea:
GH_TOKEN=ghp_tu_token_aquí
```

### Mejores Prácticas

- ✅ Usa tokens con scopes mínimos necesarios
- ✅ Rota tokens cada 90 días
- ✅ Nunca compartas `.env` sin encriptar
- ✅ Usa `.env.local.age` para secretos personales
- ❌ Nunca hagas commit de tokens en texto plano

---

## 📚 Recursos Adicionales

### Documentación Oficial

- 📘 [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) - Estándar abierto para extensiones de IA
- 🔗 [Conventional Commits](https://www.conventionalcommits.org/) - Especificación de mensajes de commit
- 📖 [Semantic Versioning](https://semver.org/) - Versionado semántico 2.0.0
- 🐙 [GitHub CLI](https://cli.github.com/) - Documentación de `gh`

### Repositorios de Extensiones MCP

- [Chrome DevTools MCP](https://github.com/ChromeDevTools/chrome-devtools-mcp) - Debugging de navegadores
- [GitHub MCP Server](https://github.com/github/github-mcp-server) - Integración con GitHub
- [Postgres MCP](https://github.com/gemini-cli-extensions/postgres) - Cliente PostgreSQL
- [Nanobanana MCP](https://github.com/gemini-cli-extensions/nanobanana) - Utilidades de productividad

### Tutoriales y Guías

- [Crear tu primer workflow personalizado](../docs/workflows-guide.md) (próximamente)
- [Configurar MCP servers locales](../docs/mcp-local-setup.md) (próximamente)
- [Mejores prácticas para commits](../docs/commit-best-practices.md) (próximamente)

---

<p align="center">
  <sub>
    Configuración optimizada para desarrollo productivo con IA<br>
    <a href="https://github.com/herwingx/dotfiles">⭐ Star este repo</a> si te resultó útil
  </sub>
</p>
