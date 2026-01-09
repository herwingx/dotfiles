---
description: Eliminar ramas locales y remotas ya fusionadas
---

# /limpiar-ramas

1.  **Limpieza Local**
    *   Elimina ramas locales que ya han sido fusionadas ("gone"):
    // turbo
    ```bash
    git fetch -p && git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -D
    ```

2.  **Estado**
    *   Muestra ramas restantes: `git branch`
