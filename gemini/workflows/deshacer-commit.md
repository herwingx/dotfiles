---
description: Deshacer el último commit manteniendo los cambios en el área de staging
---

# Deshacer Último Commit

Este workflow permite revertir el último commit local **sin perder el trabajo realizado**. Los archivos volverán al estado "staged" (listos para commit de nuevo).

## Pasos

1.  **Informar Acción**
    *   Explica que se ejecutará un `soft reset` al commit anterior (`HEAD~1`).
    *   Aclara que los cambios **NO** se perderán, solo se deshace el "empaquetado" del commit.

2.  **Ejecutar Reset**
    *   Ejecuta el comando:
        ```bash
        git reset --soft HEAD~1
        ```
    // turbo

3.  **Verificar Estado**
    *   Muestra el estado actual para confirmar que los archivos están en staging:
        ```bash
        git status
        ```

## ¿Cuándo usar esto?
- Te equivocaste en el mensaje del commit (aunque `git commit --amend` también sirve).
- Se te olvidó agregar un archivo al último commit.
- Quieres juntar el trabajo de ese commit con cambios nuevos antes de commitear.
