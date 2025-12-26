---
description: Crear Pull Request en GitHub
---

# Crear Pull Request

Crea un PR para fusionar la rama de trabajo a main.

## Prerequisitos
- GitHub CLI (`gh`) instalado y autenticado
- Rama publicada en el remoto

## Pasos

1. Verificar que gh está disponible
```bash
gh --version
```

2. Verificar autenticación
```bash
gh auth status
```

3. Verificar rama actual
```bash
git branch --show-current
```

4. Verificar que la rama está publicada
```bash
git ls-remote --heads origin $(git branch --show-current)
```
> Si no está publicada, ejecutar primero el workflow de publicar

5. Crear PR con título en formato Conventional Commits
```bash
gh pr create --title "type(scope): descripción" --body "## Descripción
[Descripción de los cambios]

## Cambios Realizados
- [Cambio 1]
- [Cambio 2]

## Testing
- [ ] Tests unitarios
- [ ] Tests de integración

## Checklist
- [ ] Código sigue estándares del proyecto
- [ ] Sin console.log ni código comentado
- [ ] Documentación actualizada

Closes #ISSUE_NUMBER" --web
```

## Formato del Título
Debe seguir Conventional Commits:
- `feat(auth): implementar login con JWT`
- `fix(ui): corregir responsive en móviles`
- `refactor(api): optimizar consultas de usuarios`

## Condición de Retorno
Retornar cuando el PR esté creado.
El flag `--web` abrirá el navegador para revisar y ajustar el PR.
Recordar:
- Usar Squash and Merge al fusionar
- Eliminar la rama después del merge
