---
description: Crear Pull Request usando GitHub CLI
---

# /crear-pr

1.  **Validaciones**
    *   Asegura estar en una rama de feature/fix (no main).
    *   Asegura que la rama está publicada (`git ls-remote`). Si no, ejecutas `/publicar`.

2.  **Crear PR**
    *   Usa el título del último commit o pide uno nuevo.
    *   Ejecuta:
        ```bash
        gh pr create --fill
        ```
    *   `--fill`: Autocompleta título y body con la info de los commits.
    *   (Sin `--web` para compatibilidad con servidores headless).
