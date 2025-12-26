---
description: Eliminar ramas locales y remotas que ya fueron fusionadas
---

# Limpiar Ramas Fusionadas

Elimina las ramas que ya fueron fusionadas a main para mantener el repositorio limpio.

## Pasos

1. Cambiar a main y actualizar
```bash
git checkout main && git pull origin main
```

2. Ver ramas locales fusionadas
```bash
git branch --merged main
```

3. Eliminar ramas locales fusionadas (excepto main)
```bash
git branch --merged main | findstr /v "main" | ForEach-Object { git branch -d $_.Trim() }
```
> En PowerShell. Para bash usar: `git branch --merged main | grep -v "main" | xargs git branch -d`

4. Ver ramas remotas
```bash
git branch -r
```

5. Podar referencias remotas obsoletas
// turbo
```bash
git remote prune origin
```

6. Eliminar rama remota específica (si el usuario lo solicita)
```bash
git push origin --delete nombre-rama
```

## Condición de Retorno
Retornar con lista de ramas eliminadas.
Confirmar que main y ramas activas siguen intactas.
