---
description: Iniciar una nueva feature branch desde main actualizado
---

# /nueva-feature

1.  **Actualizar Main**
    // turbo
    ```bash
    git checkout main && git pull origin main
    ```

2.  **Crear Rama**
    *   Solicita nombre descriptivo (kebab-case).
    *   Crea la rama: `git checkout -b feat/nombre-feature`

3.  **Confirmar**
    *   Muestra: `git branch --show-current`
