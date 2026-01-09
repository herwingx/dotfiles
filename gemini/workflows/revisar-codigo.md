---
description: Code Review local o de PR
---

# /revisar-codigo

1.  **Diff**
    *   Local: `git diff`
    *   PR: `gh pr diff <id>`

2.  **Checklist**
    *   🔴 **Bugs/Seguridad**: Errores lógicos, credenciales, inyecciones.
    *   🟡 **Clean Code**: Nombres, complejidad, duplicidad.
    *   🟢 **Estilo**: Convenciones del proyecto.

3.  **Reporte**
    *   Genera lista de hallazgos accionables.
