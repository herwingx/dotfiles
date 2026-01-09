---
description: Fusionar el Pull Request actual usando Squash & Merge y borrar la rama remota y local
---

# Fusionar Pull Request (Squash & Merge)

Este workflow fusiona el Pull Request actual en la rama base (generalmente `main`) utilizando la estrategia **Squash & Merge**. Esto asegura un historial lineal y limpio.

## Pasos

1.  **Verificar estado del PR**
    *   Ejecuta `gh pr status` para asegurar que estás en una rama con un PR abierto.
    *   Verifica que los checks de CI hayan pasado (si aplica).

2.  **Confirmar fusión**
    *   Pregunta al usuario si está seguro de fusionar el PR actual.

3.  **Fusionar con Squash**
    *   Ejecuta el siguiente comando para fusionar, aplicar squash y borrar la rama remota automáticamente:
        ```bash
        gh pr merge --squash --delete-branch
        ```
    // turbo

4.  **Actualizar localmente**
    *   Cámbiate a la rama `main`: `git checkout main`
    *   Trae los cambios del remoto: `git pull origin main`
    *   Borra la rama local de la feature/fix ya fusionada:
        ```bash
        git branch -D <nombre_rama_anterior>
        ```
        *(Nota: Obtén el nombre de la rama antes de cambiar a main)*

## Comandos Clave
- `gh pr merge --squash --delete-branch`: Realiza la fusión, squash y borrado en GitHub.
