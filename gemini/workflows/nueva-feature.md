---
description: Iniciar desarrollo de una nueva funcionalidad
---

# Nueva Feature

Flujo para crear una rama de trabajo y empezar a desarrollar una nueva funcionalidad.

## Pasos

1. Verificar que estamos en un repositorio Git
```bash
git status
```

2. Sincronizar con main
// turbo
```bash
git checkout main && git pull origin main
```

3. Crear rama de trabajo con el nombre proporcionado por el usuario
```bash
git checkout -b feat/NOMBRE_FEATURE_EN_INGLES
```
> Reemplazar `NOMBRE_FEATURE_EN_INGLES` con el nombre en inglés, kebab-case

4. Confirmar creación exitosa
```bash
git branch --show-current
```

## Condición de Retorno
Retornar cuando la rama esté creada y el usuario esté listo para desarrollar.
Informar el nombre de la rama creada y recordar:
- Hacer commits frecuentes con Conventional Commits
- Sincronizar con main periódicamente
