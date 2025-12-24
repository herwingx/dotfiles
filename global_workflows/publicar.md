---
description: Publicar rama al repositorio remoto
---

# Publicar Rama

Sube la rama de trabajo al repositorio remoto en GitHub.

## Pasos

1. Verificar rama actual
```bash
git branch --show-current
```

2. Verificar que no estamos en main
> Si estamos en main, ABORTAR y avisar al usuario que no debe hacer push directo a main

3. Verificar si la rama ya existe en remoto
```bash
git ls-remote --heads origin $(git branch --show-current)
```

4. Publicar rama

### Si es la primera vez (rama nueva):
```bash
git push -u origin HEAD
```

### Si la rama ya existe y se hizo rebase:
```bash
git push --force-with-lease
```
> `--force-with-lease` es más seguro que `--force`, evita sobrescribir trabajo de otros

### Si la rama ya existe sin rebase:
// turbo
```bash
git push
```

## Condición de Retorno
Retornar cuando el push esté completo.
Mostrar la URL de la rama en GitHub si está disponible.
Sugerir crear Pull Request si el desarrollo está listo.
