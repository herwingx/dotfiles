---
description: Crear un commit atómico siguiendo Conventional Commits
---

# /commit

1.  **Staging**
    *   Muestra cambios: `git status -sb`
    *   Si el usuario confirma "todo": `git add .`
    *   Si no, pregunta qué archivos agregar.

2.  **Commit**
    *   Genera un mensaje siguiendo **Conventional Commits**: `type(scope): descripción`
    *   Ejecuta: `git commit -m "mensaje"`

> **Tipos**: `feat` (feature), `fix` (bug), `docs` (doc), `style` (format), `refactor` (code), `test` (tests), `chore` (maint).
