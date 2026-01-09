---
description: Revisar código local o PR buscando mejoras, errores o violaciones de estilo
---

# Revisión de Código (Code Review)

Este workflow guía al agente para realizar una revisión exhaustiva del código actual.

## Pasos

1.  **Identificar Contexto**
    *   ¿Se revisará el código en el directorio actual (cambios no commiteados) o un PR específico?
    *   Si son cambios locales:
        ```bash
        git diff
        ```
    *   Si es un PR (opcional, requiere ID):
        ```bash
        gh pr diff <id>
        ```

2.  **Análisis Estático y Lógico**
    *   Revisa el código buscando:
        - **Errores lógicos**: Bugs potenciales, condiciones de borde.
        - **Seguridad**: Credenciales expuestas, inyecciones SQL/XSS.
        - **Clean Code**: Nombres de variables, funciones muy largas, complejidad ciclomática.
        - **Estilo**: Adherencia a las guías del proyecto.
        - **Rendimiento**: Bucles ineficientes, N+1 queries.

3.  **Generar Reporte**
    *   Provee un resumen estructurado con:
        - 🔴 **Crítico**: Bugs o problemas de seguridad.
        - 🟡 **Mejora**: Refactorización sugerida.
        - 🟢 **Nitpick**: Detalles menores de estilo.

4.  **Sugerir Refactorización (Opcional)**
    *   Si el usuario lo pide, aplica las correcciones sugeridas directamente.
