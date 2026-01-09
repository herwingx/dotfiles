---
description: Publicar rama actual al remoto
---

# /publicar

1.  **Push Inteligente**
    *   Si es rama nueva:
        ```bash
        git push -u origin HEAD
        ```
    *   Si ya existe (y necesita force por rebase):
        ```bash
        git push --force-with-lease
        ```
    *   Si es update normal:
        ```bash
        git push
        ```

2.  **Ver en GitHub**
    // turbo
    ```bash
    gh browse -b $(git branch --show-current)
    ```
