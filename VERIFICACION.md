# 📋 Guía de Verificación - Dotfiles Setup

> **Fecha:** 2026-01-09  
> **Objetivo:** Verificar que todos los componentes de dotfiles funcionen correctamente

---

## 🔧 Problemas Corregidos

### 1. ✅ Error de Ble.sh
**Problema:**
```bash
bash: ble-opt: command not found
ble-face: face 'auto_complete_data' not found
```

**Causa:** Los comandos `ble-opt` y `ble-face` se ejecutaban antes de que ble.sh estuviera completamente cargado.

**Solución:** Modificado `.blerc` para usar `bleopt` y proteger los comandos `ble-face` con verificación de `BLE_VERSION`.

### 2. ✅ Error install_auto_update
**Problema:**
```bash
./install.sh: line 29: install_auto_update: command not found
```

**Causa:** Función `install_modern_tools()` estaba duplicada en `scripts/system.sh`, rompiendo el flujo de carga del script.

**Solución:** Eliminada la definición duplicada e incompleta de la función.

---

## 🧪 Pasos de Verificación

### Paso 1: Verificar Sintaxis de Scripts

```bash
# Verificar que no haya errores de sintaxis
bash -n install.sh && echo "✓ install.sh OK"
bash -n scripts/system.sh && echo "✓ system.sh OK"
bash -n scripts/dev-tools.sh && echo "✓ dev-tools.sh OK"
bash -n scripts/antigravity.sh && echo "✓ antigravity.sh OK"
bash -n scripts/git.sh && echo "✓ git.sh OK"
bash -n scripts/cloud.sh && echo "✓ cloud.sh OK"
bash -n scripts/common.sh && echo "✓ common.sh OK"
```

**Resultado esperado:** Todos los scripts deben mostrar "OK" sin errores.

---

### Paso 2: Verificar Estructura de Archivos

```bash
# Verificar que todos los archivos de configuración existan
ls -lh config/
```

**Archivos esperados:**
- ✅ `.bash_aliases` - Aliases de bash
- ✅ `.gitconfig` - Configuración de Git
- ✅ `.tmux.conf` - Configuración de Tmux
- ✅ `herwingx.omp.json` - Tema de Oh My Posh

---

### Paso 3: Probar Instalación Limpia (Opcional)

⚠️ **ADVERTENCIA:** Solo ejecutar en un entorno de prueba o si estás seguro.

```bash
# Ejecutar el instalador en modo interactivo
./install.sh
```

**Opciones a probar:**
1. **Opción 6:** Paquetes base + herramientas
   - Debe instalar: lsd, fzf, tmux, zoxide, bat, ripgrep, delta
   - Debe configurar: ble.sh, oh-my-posh, atuin

2. **Opción 7:** Git Config
   - Debe copiar `.gitconfig` a `~/.gitconfig`

---

### Paso 4: Verificar Configuración de Ble.sh

```bash
# Ver el contenido del .blerc generado
cat ~/.blerc
```

**Contenido esperado:**
```bash
# ==============================================================================
# CONFIGURACIÓN VISUAL BLE.SH
# ==============================================================================
# IMPORTANTE: Este archivo se carga DESPUÉS de que ble.sh esté inicializado
# Los comandos ble-face y bleopt solo están disponibles en ese momento

# 1. Estilo Fish-like (Sugerencias grises, SIN subrayado ni fondo)
bleopt complete_auto_complete=1
bleopt complete_menu_style=align-nowrap

# 2. Configurar colores (se ejecutan cuando ble.sh ya está cargado)
if [[ ${BLE_VERSION-} ]]; then
    ble-face -s auto_complete fg=242,bg=default,ul=none
    ble-face -s syntax_error fg=196,bg=default
    ble-face -s syntax_varname fg=208
    ble-face -s syntax_quoted fg=107
fi
```

---

### Paso 5: Verificar Tmux Configuration

```bash
# Ver configuración de tmux
cat ~/.tmux.conf
```

**Debe contener:**
- Configuración de prefix key
- Configuración de colores
- Configuración de plugins (si aplica)

---

### Paso 6: Verificar Herramientas Instaladas

```bash
# Verificar que las herramientas modernas estén instaladas
command -v zoxide && echo "✓ zoxide instalado"
command -v bat || command -v batcat && echo "✓ bat instalado"
command -v rg && echo "✓ ripgrep instalado"
command -v delta && echo "✓ git-delta instalado"
command -v lsd && echo "✓ lsd instalado"
command -v oh-my-posh && echo "✓ oh-my-posh instalado"
command -v atuin && echo "✓ atuin instalado"
```

---

### Paso 7: Verificar Estado de Git

```bash
# Ver estado del repositorio
git status

# Ver últimos commits
git log --oneline -5

# Verificar que no haya ramas huérfanas
git branch -a
```

**Estado esperado:**
- ✅ En rama `main`
- ✅ Sin cambios sin commitear
- ✅ Rama `fix/blesh-config-timing` eliminada (si se hizo merge)

---

## 🐛 Solución de Problemas

### Si siguen apareciendo errores de ble.sh:

1. **Regenerar .blerc:**
   ```bash
   rm ~/.blerc
   ./install.sh
   # Seleccionar opción 6
   ```

2. **Verificar .bashrc:**
   ```bash
   # Buscar líneas de ble.sh
   grep -n "ble.sh" ~/.bashrc
   ```

   Debe tener:
   - Al inicio: `[[ $- == *i* ]] && source ~/.local/share/blesh/ble.sh --noattach`
   - Al final: `[[ ${BLE_VERSION-} ]] && ble-attach`

3. **Recargar shell:**
   ```bash
   exec bash
   ```

---

### Si install_auto_update sigue fallando:

1. **Verificar que system.sh se cargue correctamente:**
   ```bash
   source scripts/common.sh
   source scripts/system.sh
   type install_auto_update
   ```

2. **Verificar que no haya funciones duplicadas:**
   ```bash
   grep -n "^install_modern_tools()" scripts/system.sh
   ```
   
   Debe aparecer **solo una vez**.

---

## ✅ Checklist Final

- [ ] Todos los scripts pasan verificación de sintaxis
- [ ] Archivos de configuración existen en `config/`
- [ ] `.blerc` tiene la configuración correcta
- [ ] `.tmux.conf` está enlazado
- [ ] No hay errores al ejecutar `./install.sh`
- [ ] No aparecen errores de `ble-opt` o `ble-face`
- [ ] Función `install_auto_update` está disponible
- [ ] Git está en estado limpio en rama `main`
- [ ] Herramientas modernas instaladas (zoxide, bat, rg, delta, lsd)

---

## 📝 Notas Adicionales

### Sobre el commit directo a main

⚠️ **Recordatorio:** Según el protocolo, **NUNCA** se debe hacer commit directo a `main`. 

Para el futuro:
1. Crear rama: `git checkout -b tipo/nombre`
2. Hacer cambios y commits
3. Crear PR: `gh pr create --fill`
4. Fusionar: `gh pr merge --squash --delete-branch`

### Próximos Pasos Recomendados

1. **Actualizar README.md** con las correcciones realizadas
2. **Crear release** si todo funciona correctamente
3. **Documentar** las herramientas instaladas y sus configuraciones
4. **Configurar auto-update** (opción 17 del instalador)

---

## 🎯 Resumen

**Problemas corregidos:**
- ✅ Timing de carga de ble.sh
- ✅ Función duplicada en system.sh
- ✅ Errores de comando no encontrado

**Estado actual:**
- ✅ Scripts con sintaxis correcta
- ✅ Configuraciones actualizadas
- ✅ Merge realizado en main
- ✅ Rama de trabajo eliminada

**Pendiente:**
- 🔄 Probar instalación completa
- 🔄 Verificar que no haya más errores
- 🔄 Actualizar documentación
