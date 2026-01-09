---
description: Sincronizar rama actual con main usando Rebase
---

# /sync-main

1.  **Fetch & Rebase**
    *   Trae cambios sin cambiar de rama y aplica rebase:
    // turbo
    ```bash
    git fetch origin && git rebase origin/main
    ```

2.  **Resolver Conflictos (Si hay)**
    *   Si falla, instruye al usuario: "Resuelve conflictos, luego `git rebase --continue`".
    *   Si todo bien, muestra: `git status`
