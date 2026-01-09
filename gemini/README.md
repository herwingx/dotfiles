# 🤖 Gemini AI - Configuración Antigravity

> **Potencia tu asistente de IA** — Reglas de desarrollo, workflows automatizados y extensiones MCP para Gemini.

[![MCP](https://img.shields.io/badge/MCP-Model_Context_Protocol-blue?style=flat-square)](https://modelcontextprotocol.io/)
[![Gemini](https://img.shields.io/badge/Gemini-CLI-orange?style=flat-square)](https://ai.google.dev/)

---

## 📋 Índice

- [¿Qué es Antigravity?](#-qué-es-antigravity)
- [Estructura de Archivos](#-estructura-de-archivos)
- [Configuración (settings.json)](#️-configuración-settingsjson)
- [Extensiones MCP](#-extensiones-mcp)
- [Workflows Disponibles](#-workflows-disponibles)
- [Reglas de Desarrollo](#-reglas-de-desarrollo-geminimd)
- [Instalación](#-instalación)

---

## 🎯 ¿Qué es Antigravity?

**Antigravity** es el IDE de codificación agéntica avanzada de Google (**Google Advanced Agentic Coding IDE**), diseñado para trabajar en par con desarrolladores mediante IA.

Este repositorio proporciona un framework de configuración que es compatible tanto con el **IDE Antigravity** como con la **Gemini CLI**, ya que ambas herramientas comparten la misma ruta de instalación y archivos de configuración (`~/.gemini/`).

El framework combina:

1. **Reglas de Desarrollo**: Protocolos estandarizados en `GEMINI.md` (Conventional Commits, Git Flow, Clean Code)
2. **Workflows Automatizados**: Comandos slash para tareas comunes (`/commit`, `/release`, `/crear-pr`)
3. **Extensiones MCP**: Servidores que amplían las capacidades de Gemini (GitHub, Chrome DevTools, Postgres)

### Beneficios

| Beneficio          | Descripción                                                              |
| :----------------- | :----------------------------------------------------------------------- |
| ✅ **Consistencia** | Todos los commits, PRs y releases siguen el mismo estándar               |
| ✅ **Velocidad**    | Workflows preconfigurados eliminan tareas repetitivas                    |
| ✅ **Integración**  | Gemini interactúa directamente con GitHub, bases de datos y el navegador |
| ✅ **Seguridad**    | Tokens encriptados con Age, nunca expuestos en código                    |

---

## 📁 Estructura de Archivos

```
gemini/
├── GEMINI.md           # 📜 Reglas globales de desarrollo (Conventional Commits, Git Flow, etc.)
├── settings.json       # ⚙️  Configuración de Gemini CLI (extensiones MCP, tema, autenticación)
└── workflows/          # 🔄 Workflows automatizados (comandos slash)
    ├── commit.md       # Crear commits con Conventional Commits
    ├── crear-pr.md     # Crear Pull Request en GitHub
    ├── crear-readme.md # Generar README.md profesional
    ├── limpiar-ramas.md # Eliminar ramas fusionadas
    ├── nueva-feature.md # Iniciar desarrollo de feature
    ├── publicar.md     # Publicar rama al remoto
    ├── release.md      # Crear release con tag y notas
    └── sync-main.md    # Sincronizar con main usando rebase
```

---

## ⚙️ Configuración (settings.json)

El archivo `settings.json` configura el comportamiento de Gemini CLI.

### Secciones Principales

| Sección         | Propósito                               | Ejemplo                                           |
| :-------------- | :-------------------------------------- | :------------------------------------------------ |
| `mcpServers`    | Define los servidores MCP (extensiones) | GitHub, Chrome DevTools, Postgres                 |
| `security.auth` | Tipo de autenticación                   | OAuth Personal                                    |
| `general`       | Preferencias generales                  | Modo Vim (desactivado), Features preview          |
| `context`       | Filtrado de archivos                    | Respetar `.gitignore` (desactivado para dorfiles) |
| `ui`            | Tema visual                             | GitHub (claro)                                    |

### Ejemplo de Servidor MCP

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

> 📘 **Nota**: La variable `GITHUB_PERSONAL_ACCESS_TOKEN` se exporta automáticamente en `~/.bashrc` durante la instalación (extraída desde `.env.age`).

---

## 🔌 Extensiones MCP

### ¿Qué es MCP?

**Model Context Protocol (MCP)** es un estándar abierto que permite a los LLMs interactuar con herramientas externas, APIs y servicios.

### Servidores Instalados

| Extensión             | Repositorio                                                                                 | Capacidades                                                                                                 |
| :-------------------- | :------------------------------------------------------------------------------------------ | :---------------------------------------------------------------------------------------------------------- |
| 🌐 **Chrome DevTools** | [ChromeDevTools/chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) | • Inspección de elementos<br>• Control de pestañas<br>• Debugging de JavaScript<br>• Captura de screenshots |
| 🐙 **GitHub**          | [github/github-mcp-server](https://github.com/github/github-mcp-server)                     | • Gestión de repositorios<br>• Creación de issues y PRs<br>• Búsqueda de código<br>• Revisión de commits    |
| 🐘 **Postgres**        | [gemini-cli-extensions/postgres](https://github.com/gemini-cli-extensions/postgres)         | • Ejecución de queries SQL<br>• Inspección de schemas<br>• Gestión de tablas y índices                      |
| 🍌 **Nanobanana**      | [gemini-cli-extensions/nanobanana](https://github.com/gemini-cli-extensions/nanobanana)     | • Utilidades de sistema<br>• Productividad adicional                                                        |

### Instalación Manual de Extensiones

Si quieres agregar más extensiones:

```bash
# Instalar una extensión
gemini extensions install "https://github.com/usuario/repo-mcp"

# Listar extensiones instaladas
gemini extensions list

# Actualizar todas las extensiones
gemini extensions update --all

# Eliminar una extensión
gemini extensions remove nombre-extension
```

---

## 🔄 Workflows Disponibles

Los workflows se instalan en `~/.gemini/antigravity/global_workflows/` y se invocan con comandos slash.

> 🖥️ **Diseño "Terminal-First"**: Todos los workflows están optimizados para funcionar en entornos **Headless** (servidores SSH, WSL sin GUI). Utilizan exclusivamente `gh` CLI en modo texto, evitando abrir navegadores web, lo que garantiza velocidad y compatibilidad total.

### Tabla de Workflows

| Workflow         | Descripción                            | Ejemplo de Uso                               |
| :--------------- | :------------------------------------- | :------------------------------------------- |
| `/commit`        | Crear commits con Conventional Commits | "Crea un commit para los cambios en auth"    |
| `/crear-pr`      | Crear Pull Request en GitHub           | "Crea un PR para la rama feat/login"         |
| `/nueva-feature` | Iniciar desarrollo de feature          | "Inicia una feature para el módulo de pagos" |
| `/publicar`      | Publicar rama al remoto                | "Publica la rama actual"                     |
| `/release`       | Crear release con tag y notas          | "Crea un release v1.2.0"                     |
| `/sync-main`     | Sincronizar con main usando rebase     | "Sincroniza esta rama con main"              |
| `/crear-readme`  | Generar README.md profesional          | "Crea un README para este proyecto"          |
| `/limpiar-ramas` | Eliminar ramas fusionadas              | "Limpia las ramas que ya están en main"      |

### Ejemplo de Uso

```bash
# En una conversación con Gemini
Usuario: /crear-pr
Gemini: [Lee el workflow crear-pr.md y ejecuta los pasos]
        → Crea rama si no existe
        → Valida commits con Conventional Commits
        → Genera descripción del PR
        → Ejecuta: gh pr create --fill
```

### Crear Workflows Personalizados

Puedes crear tus propios workflows en `~/.gemini/antigravity/global_workflows/`:

```markdown
---
description: Descripción breve del workflow
---

# Pasos del Workflow

1. Paso 1: Hacer algo
2. Paso 2: Hacer algo más
// turbo
3. Paso 3: Este paso se auto-ejecuta (SafeToAutoRun=true)
```

> 💡 **Tip**: Usa `// turbo` antes de un paso para que se ejecute automáticamente sin pedir confirmación (solo para comandos seguros).

---

## 📜 Reglas de Desarrollo (GEMINI.md)

El archivo `GEMINI.md` contiene el protocolo completo de desarrollo que Gemini debe seguir.

### Principales Reglas

| Categoría                  | Reglas Incluidas                                                                                                                  |
| :------------------------- | :-------------------------------------------------------------------------------------------------------------------------------- |
| 🔀 **Git Flow**             | • Nunca commit directo a `main`<br>• Nomenclatura de ramas (`feat/`, `fix/`, `hotfix/`)<br>• Estrategia de merge (Squash & Merge) |
| 📝 **Conventional Commits** | • Formato: `type(scope): descripción`<br>• Breaking changes: `type!`<br>• Tipos: feat, fix, docs, refactor, etc.                  |
| 🏷️ **Versionado Semántico** | • SemVer 2.0.0 (MAJOR.MINOR.PATCH)<br>• Bump automático según tipo de commit                                                      |
| 🌐 **Idioma**               | • Código en inglés<br>• Commits y docs en español                                                                                 |
| 📖 **Documentación**        | • DocBlocks obligatorios<br>• "The Why, Not The What"<br>• Better Comments (!, ?, TODO, *)                                        |
| 🧹 **Código Limpio**        | • Sin console.log ni debuggers<br>• Sin código comentado<br>• Nomenclatura consistente                                            |

### Ejemplo de Conventional Commit

```bash
# Nueva funcionalidad
feat(auth): implementar login con Google OAuth

# Corrección de bug
fix(navbar): corregir solapamiento en móviles

# Breaking change (bump MAJOR)
feat(api)!: cambiar formato de respuesta de usuarios
```

---

## 🚀 Instalación

### Método Automático (Recomendado)

Desde el instalador principal de dotfiles:

```bash
cd ~/dotfiles
./install.sh

# Selecciona la opción:
# 4) Solo Antigravity (reglas IA + workflows)
# O
# 20) Solo Settings (settings.json + extensiones MCP)
```

### Instalación Manual

Si quieres instalar manualmente:

```bash
# 1. Crear directorio
mkdir -p ~/.gemini/antigravity/global_workflows

# 2. Copiar reglas
cp gemini/GEMINI.md ~/.gemini/

# 3. Copiar workflows
cp gemini/workflows/* ~/.gemini/antigravity/global_workflows/

# 4. Copiar configuración
cp gemini/settings.json ~/.gemini/

# 5. Configurar token de GitHub (desde .env.age)
# Esto lo hace automáticamente el script antigravity.sh
export GITHUB_PERSONAL_ACCESS_TOKEN="tu_token_aquí"
echo "export GITHUB_PERSONAL_ACCESS_TOKEN=\"tu_token_aquí\"" >> ~/.bashrc

# 6. Instalar extensiones MCP
gemini extensions install "https://github.com/ChromeDevTools/chrome-devtools-mcp"
gemini extensions install "https://github.com/github/github-mcp-server"
gemini extensions install "https://github.com/gemini-cli-extensions/postgres"
gemini extensions install "https://github.com/gemini-cli-extensions/nanobanana"
```

---

## 🔐 Seguridad

### Token de GitHub

El token de GitHub (`GH_TOKEN`) se gestiona de forma segura:

1. **Almacenamiento**: Encriptado en `.env.age` con Age
2. **Extracción**: Solo en runtime, nunca expuesto en código
3. **Persistencia**: Exportado en `~/.bashrc` como `GITHUB_PERSONAL_ACCESS_TOKEN`
4. **Uso**: Disponible para `gh` CLI y extensiones MCP

### Permisos Requeridos

Para que las extensiones funcionen correctamente, el token de GitHub debe tener estos scopes:

| Scope       | Propósito                                          |
| :---------- | :------------------------------------------------- |
| `repo`      | Acceso completo a repositorios (lectura/escritura) |
| `workflow`  | Gestión de GitHub Actions                          |
| `read:org`  | Leer información de organizaciones                 |
| `read:user` | Leer perfil de usuario                             |

---

## 📚 Recursos Adicionales

- 📘 [Model Context Protocol (MCP)](https://modelcontextprotocol.io/)
- 🔗 [Conventional Commits](https://www.conventionalcommits.org/)
- 📖 [Semantic Versioning](https://semver.org/)
- 🐙 [GitHub CLI](https://cli.github.com/)

---

<p align="center">
  <sub>
    Configuración optimizada para desarrollo productivo con IA<br>
    <a href="https://github.com/herwingx/dotfiles">⭐ Star este repo</a> si te resultó útil
  </sub>
</p>
