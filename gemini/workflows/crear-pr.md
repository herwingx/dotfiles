---
description: Crear Pull Request (PR) automáticamente usando GitHub CLI
---

# /crear-pr

## Pasos

1.  **Verificación de Estado (One-Shot)**
    *   Verifica si ya existe un PR para esta rama. Si existe, muestra su estado y URL.
    
    // turbo
    ```bash
    gh pr view --web=false
    ```

2.  **Creación Automática**
    *   Si NO existe PR, crea uno nuevo usando las **notas de commits** para el título/body.
    *   Prioriza `gh` CLI nativo para velocidad.
    
    ```bash
    gh pr create --fill --web=false
    ```

3.  **Confirmación Final**
    *   Muestra la URL del PR creado.
