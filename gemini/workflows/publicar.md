---
description: Publicar rama actual al remoto (Push robusto)
---

# /publicar

## Pasos

1.  **Push Inteligente (One-Shot)**
    *   Intenta push estándar (set-upstream).
    *   Si falla (ej. rebase necesario), intenta push force-lease (seguro).
    
    // turbo
    ```bash
    git push -u origin HEAD || git push --force-with-lease origin HEAD
    ```

2.  **Verificar estado**
    *   Muestra la URL del PR si existe, o el estado en GitHub.
    
    // turbo
    ```bash
    gh pr view --json url --jq .url || echo "Rama publicada. Usa /crear-pr para abrir Pull Request."
    ```
