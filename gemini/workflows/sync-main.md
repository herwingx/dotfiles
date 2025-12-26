---
description: Sincronizar rama actual con los últimos cambios de main usando rebase
---

# Sincronizar con Main

Trae los últimos cambios de `main` a tu rama de trabajo usando rebase (sin merge commits).

## Pasos

1. Verificar rama actual (no debe ser main)
```bash
git branch --show-current
```

2. Verificar que no hay cambios sin commitear
```bash
git status
```
> Si hay cambios pendientes, preguntar al usuario si desea hacer commit o stash primero

3. Obtener últimos cambios de origin
// turbo
```bash
git fetch origin main
```

4. Hacer rebase sobre main
```bash
git rebase origin/main
```

## Si Hay Conflictos

Informar al usuario:
1. Resolver conflictos en los archivos indicados
2. Marcar como resueltos: `git add .`
3. Continuar rebase: `git rebase --continue`
4. Si desea abortar: `git rebase --abort`

## Condición de Retorno
Retornar cuando el rebase esté completo o cuando se detecten conflictos que el usuario debe resolver.
Recordar que si ya publicó la rama, necesitará `git push --force-with-lease` después del rebase.
