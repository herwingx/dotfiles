---
description: Iniciar una rama de Hotfix para correcciones críticas en producción
---

# Iniciar Hotfix

Este workflow ayuda a crear una rama para corregir errores críticos (hotfixes), siguiendo el protocolo de Git Flow.

## Pasos

1.  **Analizar el requerimiento**
    *   Identifica el bug crítico que se debe corregir.
    *   Determina un nombre corto y descriptivo para el hotfix (en inglés).

2.  **Sincronizar Main**
    *   Asegúrate de estar en `main` y actualizado:
        ```bash
        git checkout main
        git pull origin main
        ```
    // turbo

3.  **Crear Rama de Hotfix**
    *   Crea la rama con el prefijo `hotfix/`:
        ```bash
        git checkout -b hotfix/<nombre-descriptivo>
        ```
        *Ejemplo: `hotfix/login-crash`, `hotfix/security-patch-v1`*

4.  **Confirmación**
    *   Confirma al usuario que la rama ha sido creada y está lista para trabajar.

## Reglas
- Las ramas **hotfix** son para errores en producción que no pueden esperar al ciclo normal.
- Siempre deben nacer de `main`.
