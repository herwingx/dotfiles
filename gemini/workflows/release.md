---
description: Crear un release con tag y notas en GitHub
---

# Crear Release

Crea un tag de versión y genera un release en GitHub con notas automáticas.

## Prerequisitos
- GitHub CLI (`gh`) instalado y autenticado
- Estar en la rama `main` actualizada

## Pasos

1. Cambiar a main y actualizar
```bash
git checkout main && git pull origin main
```

2. Ver último tag para determinar nueva versión
```bash
git tag --sort=-version:refname | head -5
```

3. Determinar nueva versión según SemVer
| Cambio | Incrementar | Ejemplo |
|:-------|:------------|:--------|
| Breaking changes | MAJOR | v1.0.0 → v2.0.0 |
| Nueva funcionalidad | MINOR | v1.0.0 → v1.1.0 |
| Corrección de bug | PATCH | v1.0.0 → v1.0.1 |

4. Crear tag anotado
```bash
git tag -a vX.Y.Z -m "Release vX.Y.Z: Descripción breve"
```
> Reemplazar X.Y.Z con la versión correspondiente

5. Subir tag a GitHub
```bash
git push origin vX.Y.Z
```

6. Crear Release en GitHub con notas automáticas
```bash
gh release create vX.Y.Z --generate-notes
```

## Alternativa: Release con Notas Personalizadas
```bash
gh release create vX.Y.Z --notes "## Novedades

### ✨ Nuevas Funcionalidades
- Feature 1
- Feature 2

### 🐛 Correcciones
- Fix 1
- Fix 2

### 📝 Otros Cambios
- Mejora X"
```

## Condición de Retorno
Retornar cuando el release esté publicado en GitHub.
Proporcionar el enlace al release.
