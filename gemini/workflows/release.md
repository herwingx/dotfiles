---
description: Crear Release y Tag en GitHub
---

# /release

1.  **Preparar**
    *   Asegura estar en `main` actualizado.
    *   Calcula siguiente versión (SemVer) basada en cambios.

2.  **Lanzar**
    *   Crea tag y release en un paso:
        ```bash
        gh release create vX.Y.Z --generate-notes
        ```
    *   `--generate-notes`: Crea changelog automático basado en PRs.

3.  **Confirmar**
    *   Muestra URL del release.
