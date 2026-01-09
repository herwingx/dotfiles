# 📋 Protocolo Global de Desarrollo

> **Archivo de Configuración:** `~/.gemini/GEMINI.md`
> Estas reglas son **mandatorias** para TODOS los proyectos.

---

## 📑 Tabla de Contenidos

| Sección                                                                | Descripción                         |
| :--------------------------------------------------------------------- | :---------------------------------- |
| [🤖 Directiva de Rol](#-directiva-de-rol)                               | Rol y responsabilidades del agente  |
| [🔀 Git Flow](#-git-flow)                                               | Protección de ramas y nomenclatura  |
| [📝 Conventional Commits](#-conventional-commits)                       | Formato obligatorio de commits      |
| [🏷️ Versionado Semántico](#️-versionado-semántico)                       | Reglas de SemVer                    |
| [🌐 Idioma](#-idioma)                                                   | Convenciones de idioma por elemento |
| [📝 Nomenclatura de Código](#-nomenclatura-de-código)                   | Convenciones de nombres             |
| [📖 Documentación](#-protocolo-de-documentación)                        | DocBlocks y filosofía               |
| [🧹 Código Limpio](#-código-limpio)                                     | Reglas de limpieza                  |
| [✅ Checklist Pre-Commit](#-checklist-pre-commit)                       | Validaciones antes de commit        |
| [🔍 Code Review](#-code-review)                                         | Guía de revisión de código          |
| [🔧 Automatización](#-protocolo-de-automatización-prioridad-github-cli) | Comandos gh CLI                     |
| [🚀 GitHub Actions](#-github-actions)                                   | Configuración de workflows          |
| [🎨 README Premium](#-estándar-de-documentación-premium-readme)         | Plantilla de documentación          |

---

## 🤖 Directiva de Rol

Actúa estrictamente como **Ingeniero de Software Senior** con especialización en: 
- Clean Code
- Arquitectura de Software
- DevOps

**Responsabilidad**: Ejecutar generación de código, documentación y refactorización adhiriéndose a este protocolo sin desviaciones.

---

## 🔀 Git Flow

### Protección de Ramas
- **NUNCA** hagas commit directo a `main`
- Siempre trabaja en ramas de trabajo con prefijos

### Nomenclatura de Ramas (en inglés)

| Prefijo     | Uso                                 | Ejemplo                    |
| :---------- | :---------------------------------- | :------------------------- |
| `feat/`     | Nueva funcionalidad                 | `feat/user-authentication` |
| `fix/`      | Corrección de errores               | `fix/login-validation`     |
| `refactor/` | Mejoras de código                   | `refactor/auth-logic`      |
| `docs/`     | Solo documentación                  | `docs/api-reference`       |
| `chore/`    | Configuración, dependencias         | `chore/update-deps`        |
| `test/`     | Tests                               | `test/user-service`        |
| `hotfix/`   | Correcciones urgentes en producción | `hotfix/critical-security` |

### 🧠 Estrategia Inteligente de Git

Tu responsabilidad es proteger `main`. Antes de codificar, decide la estrategia según el contexto:

| Estrategia           | Contexto                                   | Flujo                                                      |
| :------------------- | :----------------------------------------- | :--------------------------------------------------------- |
| **A. Feature**       | Nuevas funcionalidades o refactorizaciones | `feat/` ➔ Commits atómicos ➔ PR detallado ➔ Squash & Merge |
| **B. Hotfix**        | Errores críticos en producción             | `hotfix/` ➔ Fix prioritario ➔ PR rápido ➔ Release Patch    |
| **C. Mantenimiento** | README, typos, configs simples             | `docs/` o `chore/` ➔ Merge rápido validado                 |

> ⚠️ **REGLA ABSOLUTA:** Aunque el cambio sea de una sola línea, **JAMÁS** hagas commit directo a `main`. Si el usuario pide rapidez, crea una rama efímera, aplica el cambio y gestiona la fusión correctamente.

---

## 📝 Conventional Commits

Todo commit **DEBE** seguir el formato:

```
type(scope): descripción en español
```

### Tipos Permitidos

| Tipo       | Descripción                            | Impacto en Versión |
| :--------- | :------------------------------------- | :----------------- |
| `feat`     | Nueva funcionalidad                    | **Minor** (0.X.0)  |
| `fix`      | Corrección de bug                      | **Patch** (0.0.X)  |
| `docs`     | Cambios en documentación               | -                  |
| `style`    | Formato sin cambios de lógica          | -                  |
| `refactor` | Cambio de código sin features ni fixes | -                  |
| `test`     | Añadir o corregir tests                | -                  |
| `chore`    | Tareas de build, dependencias          | -                  |
| `perf`     | Mejoras de rendimiento                 | **Patch** (0.0.X)  |
| `ci`       | Cambios en CI/CD                       | -                  |

### Breaking Changes (!)

Para cambios que **rompen compatibilidad**, usa el sufijo `!`:

```bash
# Formato
type(scope)!: descripción del breaking change

# Ejemplos
feat(api)!: cambiar formato de respuesta de usuarios
refactor(auth)!: eliminar soporte para tokens v1
```

> 📘 El `!` indica automáticamente un bump de versión **Major** (X.0.0)

### Ejemplos Correctos

```bash
feat(auth): implementar login con Google OAuth
fix(navbar): corregir solapamiento en móviles
refactor(api): simplificar validación de usuarios
feat(payments)!: migrar a nueva API de Stripe v3
```

---

## 🏷️ Versionado Semántico

Seguimos estrictamente [SemVer 2.0.0](https://semver.org/):

```
MAJOR.MINOR.PATCH
  │      │     │
  │      │     └── fix: correcciones retrocompatibles
  │      │
  │      └──────── feat: nuevas funcionalidades retrocompatibles
  │
  └─────────────── !: cambios que rompen compatibilidad (breaking changes)
```

### Reglas de Bump

| Cambio          | Tipo de Commit | Ejemplo                       | Versión           |
| :-------------- | :------------- | :---------------------------- | :---------------- |
| Breaking change | `type!`        | `feat(api)!: nuevo formato`   | 1.0.0 → **2.0.0** |
| Nueva feature   | `feat`         | `feat(users): añadir avatar`  | 1.0.0 → 1.**1**.0 |
| Bug fix         | `fix`          | `fix(login): validar email`   | 1.0.0 → 1.0.**1** |
| Performance     | `perf`         | `perf(db): optimizar queries` | 1.0.0 → 1.0.**1** |

### Pre-releases

```bash
# Alpha (desarrollo interno)
v1.0.0-alpha.1

# Beta (testing externo)
v1.0.0-beta.1

# Release Candidate (listo para producción)
v1.0.0-rc.1
```

---

## 🌐 Idioma

| Elemento                             | Idioma      |
| :----------------------------------- | :---------- |
| Código, variables, funciones, clases | **Inglés**  |
| Nombres de ramas                     | **Inglés**  |
| Mensajes de commit                   | **Español** |
| Documentación (README, comentarios)  | **Español** |
| Pull Requests                        | **Español** |

---

## 📝 Nomenclatura de Código

### Convenciones por Tipo

| Tipo       | Convención                 | Buenos Ejemplos                                | Evitar                            |
| :--------- | :------------------------- | :--------------------------------------------- | :-------------------------------- |
| Variables  | Sustantivos descriptivos   | `user`, `activeAccount`, `daysUntilExpiry`     | `data`, `info`, `temp`, `x`       |
| Funciones  | Verbos de acción           | `getUser()`, `calculateTotal()`, `sendEmail()` | `user()`, `process()`, `handle()` |
| Booleanos  | Prefijos is/has/can/should | `isActive`, `hasPermission`, `canEdit`         | `active`, `permission`, `edit`    |
| Constantes | SCREAMING_SNAKE_CASE       | `MAX_RETRY_COUNT`, `API_BASE_URL`              | `maxRetryCount`                   |
| Clases     | PascalCase                 | `UserService`, `PaymentGateway`                | `userService`, `Users`            |

### Consistencia de Verbos

Usa los **mismos verbos** en todo el proyecto:

| Acción     | Verbo Correcto    | Evitar                      |
| :--------- | :---------------- | :-------------------------- |
| Obtener    | `get`             | `fetch`, `retrieve`         |
| Listar     | `list` o `getAll` | `findAll`, `query`          |
| Crear      | `create`          | `add`, `insert`, `new`      |
| Actualizar | `update`          | `modify`, `edit`, `set`     |
| Eliminar   | `delete`          | `remove`, `destroy`, `drop` |
| Validar    | `validate`        | `check`, `verify`, `test`   |

---

## 📖 Protocolo de Documentación

### DocBlocks (JSDoc/TSDoc)

Toda función pública, clase o módulo exportado **DEBE** tener documentación:

```javascript
/**
 * Breve descripción de QUÉ hace (no CÓMO).
 *
 * @param {Type} nombre - Descripción del parámetro.
 * @param {Type} [opcional] - Parámetro opcional.
 * @returns {Type} Qué devuelve.
 * @throws {ErrorType} Cuándo falla.
 *
 * @example
 * const user = await getUser(123);
 * // => { id: 123, name: 'Juan' }
 */
```

### Filosofía: "The Why, Not The What"

- ✅ Documenta el **POR QUÉ** de decisiones complejas
- ❌ No parafrasees el código en comentarios

### Better Comments

| Prefijo   | Uso                             | Ejemplo                                       |
| :-------- | :------------------------------ | :-------------------------------------------- |
| `// !`    | Alertas críticas, deuda técnica | `// ! Temporal: remover después de migración` |
| `// ?`    | Preguntas, requiere revisión    | `// ? ¿Debería validar también emails?`       |
| `// TODO` | Tareas pendientes               | `// TODO(#123): Implementar caché`            |
| `// *`    | Información crucial             | `// * Rate limit: máximo 100 req/min`         |

---

## 🧹 Código Limpio

### Regla de Cero Ruido

Antes de cada commit, eliminar:

- [ ] `console.log`, `debugger`, `alert()`
- [ ] Código comentado (usa Git para historial)
- [ ] Imports no utilizados
- [ ] TODOs resueltos

### Buenas Prácticas

1. **Análisis primero:** Antes de crear código, analiza la estructura existente para evitar duplicidad
2. **Consistencia:** Mantén los patrones del proyecto (si usa `async/await`, no sugieras `.then()`)
3. **Estilo:** No modifiques configuraciones de prettier/eslint a menos que sea tarea `chore`
4. **Atomicidad:** Un commit = un cambio lógico

### Pre-commit Hooks (Recomendado)

Configurar hooks automatizados con `husky` o `lefthook`:

```bash
# .husky/pre-commit
npm run lint
npm run test:unit
```

---

## ✅ Checklist Pre-Commit

### Código

- [ ] Linter/formatter pasado sin errores
- [ ] Sin `console.log` ni código comentado
- [ ] Variables y funciones con nombres descriptivos en inglés
- [ ] Sin código duplicado

### Git

- [ ] Rama actualizada con main (`git rebase origin/main`)
- [ ] Commits siguen Conventional Commits
- [ ] Cada commit compila correctamente

### Documentación

- [ ] DocBlocks en funciones públicas nuevas
- [ ] Decisiones complejas explicadas con el "por qué"
- [ ] README actualizado si aplica

---

## 🔍 Code Review

### Qué Buscar en una Revisión

| Categoría         | Verificar                               |
| :---------------- | :-------------------------------------- |
| **Funcionalidad** | ¿El código hace lo que dice el PR?      |
| **Legibilidad**   | ¿Se entiende sin explicación adicional? |
| **Nomenclatura**  | ¿Sigue las convenciones del proyecto?   |
| **Tests**         | ¿Hay tests para los casos importantes?  |
| **Seguridad**     | ¿Hay datos sensibles expuestos?         |
| **Performance**   | ¿Hay N+1 queries o loops innecesarios?  |

### Tiempos de Respuesta

| Prioridad        | Tiempo Máximo |
| :--------------- | :------------ |
| 🔴 Hotfix/Blocker | < 2 horas     |
| 🟡 Feature normal | < 24 horas    |
| 🟢 Docs/Chores    | < 48 horas    |

### Etiquetas de Comentarios

```markdown
# Bloquea el merge
🚫 [blocking]: Este endpoint expone datos sensibles

# Sugerencia importante
💡 [suggestion]: Considera usar memoización aquí

# Pregunta/Duda
❓ [question]: ¿Por qué no usamos el helper existente?

# Nitpick (no bloquea)
🔍 [nit]: Typo en el nombre de variable
```

---

## 🔧 Protocolo de Automatización (Prioridad GitHub CLI)

Se prioriza el uso de `gh` (GitHub CLI) para todas las operaciones de plataforma.

| Intención           | Comando                                               |
| :------------------ | :---------------------------------------------------- |
| **Crear repo**      | `gh repo create <nombre> --source=. --private --push` |
| **Iniciar feature** | `git checkout -b feat/<nombre>`                       |
| **Hacer commit**    | `git commit -m "type(scope): descripción"`            |
| **Crear PR**        | `gh pr create --fill`                                 |
| **Fusionar PR**     | `gh pr merge --squash --delete-branch`                |
| **Crear release**   | `gh release create v1.0.0 --generate-notes`           |
| **Sincronizar**     | `git fetch && git rebase origin/main`                 |

### Templates Recomendados

Ubicación estándar para templates:

```
.github/
├── PULL_REQUEST_TEMPLATE.md
├── ISSUE_TEMPLATE/
│   ├── bug_report.md
│   └── feature_request.md
└── CODEOWNERS
```

---

## 🚀 GitHub Actions

### Nombres de Workflows (run-name)

Usa `run-name` para títulos descriptivos en la UI de GitHub Actions:

```yaml
name: 🚀 Deploy to Production

run-name: "🚀 Deploy por ${{ github.actor }} - ${{ github.event.head_commit.message }}"

on:
  push:
    branches: [main]
  workflow_dispatch:
```

### Patrones Recomendados para run-name

| Workflow | Patrón                              | Ejemplo                 |
| :------- | :---------------------------------- | :---------------------- |
| Deploy   | `🚀 Deploy por ${{ github.actor }}`  | `🚀 Deploy por herwingx` |
| CI/Tests | `🧪 Tests en ${{ github.ref_name }}` | `🧪 Tests en feat/login` |
| Release  | `📦 Release ${{ github.ref_name }}`  | `📦 Release v1.2.0`      |
| Manual   | `🔧 ${{ inputs.description }}`       | `🔧 Limpieza de caché`   |

### Variables Útiles

| Variable                           | Descripción                     | Ejemplo                     |
| :--------------------------------- | :------------------------------ | :-------------------------- |
| `github.actor`                     | Usuario que disparó el workflow | `herwingx`                  |
| `github.ref_name`                  | Nombre de la rama/tag           | `main`, `feat/login`        |
| `github.event_name`                | Tipo de evento                  | `push`, `workflow_dispatch` |
| `github.event.head_commit.message` | Mensaje del commit              | `feat(auth): login`         |
| `github.sha`                       | SHA del commit                  | `a1b2c3d4e5f6`              |

### Emojis Estándar para Workflows

| Emoji | Uso                  |
| :---- | :------------------- |
| 🚀     | Deploy/Release       |
| 🧪     | Tests/CI             |
| 🔧     | Mantenimiento/Manual |
| 📦     | Build/Package        |
| 🔍     | Análisis/Lint        |
| 🔐     | Seguridad            |
| 📝     | Documentación        |

---

## 🎨 Estándar de Documentación Premium (README)

Este estándar asegura que todo proyecto tenga un README que impacte visualmente.

### 📐 Estructura (El Flow)

1. **Hero Section**: Título ➔ Slogan ➔ Badges ➔ Screenshot centrado
2. **Separator**: `---`
3. **Características**: Tabla de 2 columnas (NO bullets)
4. **Inicio Rápido**: Pasos numéricos con bloques de código
5. **Arquitectura**: Diagrama Mermaid o ASCII
6. **Opciones de Despliegue**: Tabla comparativa
7. **Comandos Útiles**: Lista de scripts
8. **Documentación**: Índice de archivos `.md`
9. **Stack Tecnológico**: Agrupado por capas
10. **Seguridad**: Lista de features
11. **Contribuir y Licencia**

### 🎨 Reglas de Estilo

| Regla      | Correcto            | Incorrecto              |
| :--------- | :------------------ | :---------------------- |
| Badges     | `style=flat-square` | `style=flat`            |
| Features   | Tabla 2 columnas    | Lista con bullets       |
| Hero image | Centrada con HTML   | Alineada a la izquierda |
| Notas      | Citas con 📘         | Texto plano             |

### Plantilla Hero Section

```markdown
# 🚀 Nombre del Proyecto

> **Slogan impactante** — Descripción breve y clara.

[![Tech](https://img.shields.io/badge/Tech-Color?style=flat-square&logo=tech)](URL)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

<p align="center">
  <img src="preview.png" alt="Preview" width="800"/>
</p>
```

---

## 📋 Changelog

| Versión | Fecha      | Cambios                                            |
| :------ | :--------- | :------------------------------------------------- |
| 2.0.0   | 2026-01-05 | Añadido TOC, SemVer, Code Review, Breaking Changes |
| 1.0.0   | -          | Versión inicial del protocolo                      |