# ⚡ PROTOCOLO DE ACCIÓN INMEDIATA

> **MODO: EJECUCIÓN** | **PRIORIDAD: VELOCIDAD Y EFICIENCIA**
> NO expliques conceptos. NO pidas confirmaciones obvias. EJECUTA.

---

## 1. 🚀 Directivas de Comportamiento (CRÍTICO)

1.  **Output Primero**: Entrega código o comandos **inmediatamente**. Minimiza la conversación.
2.  **Sin Tutoriales**: Asume que el usuario es experto. No expliques qué es SemVer o GitFlow. Solo aplícalo.
3.  **Stack Preferido**: Usa `gh` CLI sobre comandos manuales de git siempre que sea posible.
4.  **Idioma**:
    * **Código**: INGLÉS (Variables, Funciones, Clases).
    * **Commits/Docs/PRs**: ESPAÑOL.

---

## 2. 🔀 Git & GitHub Action Flow

**Regla de Oro**: `main` es intocable. Todo cambio va vía PR.

### Estrategia de Ramas (Selección Rápida)
* Nueva Feature → `feat/<nombre-ingles-kebab-case>`
* Bug Fix → `fix/<nombre-ingles-kebab-case>`
* Config/Deps → `chore/<nombre-corto>`
* Docs → `docs/<nombre-corto>`

### ⚡ Workflow de Subida Rápida (Standard)
Cuando el usuario pida "subir", "guardar" o "deploy", ejecuta esta secuencia sin preguntar:

1.  **Staging Inteligente**: `git add .` (A menos que se especifique archivo).
2.  **Commit Atómico**:
    * Formato: `type(scope): descripción imperativa en español`
    * Tipos: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`.
    * *Breaking*: `type(scope)!:` (Añadir `!` si rompe compatibilidad).
3.  **Push & PR (One-Shot)**:
    ```bash
    # Si la rama no existe en remoto:
    git push -u origin HEAD
    
    # Crear PR inmediatamente (autocompletar título/body):
    gh pr create --fill --web=false
    ```

---

## 3. 🧹 Clean Code & Validaciones (En tiempo real)

Aplica estas reglas **mientras generas código**, no como paso posterior:

* **Cero Ruido**: Elimina `console.log`, código comentado y `TODOs` resueltos antes de presentar el bloque.
* **Naming**:
    * Variables/Propiedades: `camelCase` (Sustantivos).
    * Clases/Componentes: `PascalCase`.
    * Constantes: `SCREAMING_SNAKE_CASE`.
    * Booleanos: Prefijos `is`, `has`, `can`, `should`.
* **Docs**: JSDoc/TSDoc obligatorio **solo en exports públicos**. Formato: "Qué hace" (no cómo).

---

## 4. 🛠️ Comandos de Automatización (Cheat Sheet)

Usa estos comandos preferentemente para máxima velocidad:

| Acción | Comando Ejecutable |
| :--- | :--- |
| **Crear Repo** | `gh repo create <nombre> --source=. --private --push` |
| **Nueva Rama** | `git checkout -b <tipo>/<nombre>` |
| **Ver PRs** | `gh pr list` |
| **Fusionar PR** | `gh pr merge --squash --delete-branch` |
| **Release** | `gh release create vX.Y.Z --generate-notes` |
| **Sync** | `git fetch origin && git rebase origin/main` |

---

## 5. 🚨 Checklist de Auto-Corrección (Interno)

Antes de emitir cualquier respuesta, verifica en <10ms:

1.  ¿El commit está en español y sigue el formato `type(scope)`?
2.  ¿El código está en inglés?
3.  ¿Estoy usando `gh` CLI en lugar de abrir el navegador?
4.  ¿He eliminado logs y comentarios basura?

**SI LA RESPUESTA ES SÍ, PROCEDE INMEDIATAMENTE.**