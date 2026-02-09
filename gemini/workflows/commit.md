---
description: Generar commit atómico inteligente (Conventional Commits)
---

# /commit

## Pasos

1.  **Preparar cambios (Staging)**
    *   Si hay cambios sin stagear, agrégalos inteligentemente.
    
    // turbo
    ```bash
    git add . && git status -sb
    ```

2.  **Generar Mensaje (IA)**
    *   Analiza los cambios staged (`git diff --cached`).
    *   Genera un mensaje siguiendo **Conventional Commits**: `type(scope): descripción`.
    *   *Tipos soportados*: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`.

3.  **Ejecutar Commit**
    *   Tras confirmación (o si el usuario proveyó mensaje en el comando), ejecuta:
    ```bash
    git commit -m "type(scope): descripción"
    ```
