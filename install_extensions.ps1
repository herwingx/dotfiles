# ==========================================
# ANTIGRAVITY EXTENSION INSTALLER (WINDOWS)
# ==========================================
# Instala extensiones desde .vscode-extensions
# directamente en Antigravity (Cursor/VSCode Fork)
# ==========================================

# 1. Definir rutas
$agyPath = "$env:LOCALAPPDATA\Programs\Antigravity\bin\antigravity.cmd"
$extensionsFile = "$PSScriptRoot\.vscode-extensions"

# 2. Verificar que exista el archivo de extensiones
if (-not (Test-Path $extensionsFile)) {
    Write-Error "No se encontró el archivo de lista: $extensionsFile"
    exit 1
}

# 3. Leer extensiones (ignorando líneas vacías y comentarios)
$extensions = Get-Content $extensionsFile | Where-Object { $_ -notmatch '^\s*#' -and $_ -notmatch '^\s*$' }

# 4. Verificar si Antigravity está instalado
if (Test-Path $agyPath) {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "ANTIGRAVITY EXTENSIONS INSTALLER" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host " - Ejecutable: $agyPath" -ForegroundColor Gray
    Write-Host " - Lista: $extensionsFile" -ForegroundColor Gray
    Write-Host " - Total: $($extensions.Count) extensiones" -ForegroundColor Gray
    Write-Host "==========================================`n" -ForegroundColor Cyan

    foreach ($ext in $extensions) {
        Write-Host "Instalando $ext..." -NoNewline
        
        # Ejecutar instalación silenciosa
        try {
            & $agyPath --install-extension $ext --force | Out-Null
            Write-Host " [OK]" -ForegroundColor Green
        } catch {
            Write-Host " [ERROR]" -ForegroundColor Red
            Write-Error $_
        }
    }

    Write-Host "`n[SUCCESS] Instalación completada." -ForegroundColor Green
    Write-Host "Reinicia Antigravity para aplicar los cambios." -ForegroundColor Cyan
} else {
    Write-Error "CRITICAL: No se encontró Antigravity en: $agyPath"
    Write-Host "Asegúrate de tener Antigravity instalado en la ruta por defecto." -ForegroundColor Yellow
}
