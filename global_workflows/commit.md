---
description: Crear un commit siguiendo Conventional Commits
---

# Hacer Commit

Crea un commit atómico siguiendo la convención de Conventional Commits.

## Pasos

1. Ver cambios pendientes
```bash
git status
```

2. Ver diferencias para entender qué cambió
```bash
git diff --stat
```

3. Agregar cambios al staging
```bash
git add .
```
> O agregar archivos específicos si el usuario lo indica

4. Crear commit con mensaje en formato Conventional Commits
```bash
git commit -m "type(scope): descripción en español"
```

## Formato del Mensaje

```
type(scope): descripción imperativa en español
```

### Tipos Permitidos
| Tipo | Cuándo Usar |
|:-----|:------------|
| `feat` | Nueva funcionalidad |
| `fix` | Corrección de bug |
| `docs` | Solo documentación |
| `style` | Formato, sin cambios de lógica |
| `refactor` | Cambio de código sin feat/fix |
| `test` | Añadir o corregir tests |
| `chore` | Build, dependencias, config |
| `perf` | Mejoras de rendimiento |
| `ci` | Cambios en CI/CD |

### Ejemplos
- `feat(auth): implementar login con Google OAuth`
- `fix(navbar): corregir solapamiento en móviles`
- `refactor(api): simplificar validación de usuarios`

## Validaciones Antes del Commit
- [ ] No hay `console.log` ni `debugger`
- [ ] No hay código comentado
- [ ] El mensaje describe el cambio, no los archivos

## Condición de Retorno
Retornar cuando el commit esté creado exitosamente.
Mostrar el hash del commit y recordar publicar cuando esté listo.
