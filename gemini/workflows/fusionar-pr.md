---
description: Fusionar PR actual (Squash & Merge) y limpiar
---

# /fusionar-pr

1.  **Fusionar**
    *   Desde la rama del PR:
        ```bash
        gh pr merge --squash --delete-branch
        ```
    *   Esto fusiona en remoto y borra la rama remota.

2.  **Limpieza Local**
    *   Vuelve a main y actualiza:
    // turbo
    ```bash
    git checkout main && git pull origin main
    ```
    *   Borra la rama local antigua (si no falló el paso anterior):
        ```bash
        git branch -D <rama-anterior>
        ```
