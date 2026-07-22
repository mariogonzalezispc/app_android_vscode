param(
    [Parameter(Mandatory = $true)]
    [string]$ActivityName
)

$ErrorActionPreference = "Stop"


# ============================================================
# CONFIGURACIÓN
# ============================================================

# Script:
# C:\DEMO_ISPC\tools\activity.ps1
#
# Proyecto:
# C:\DEMO_ISPC

$ProjectRoot = Split-Path -Parent $PSScriptRoot

$AppPath = Join-Path $ProjectRoot "app"

$MainPath = Join-Path $AppPath "src\main"

$JavaPath = Join-Path $MainPath "java"

$ResPath = Join-Path $MainPath "res"

$LayoutPath = Join-Path $ResPath "layout"

$ManifestPath = Join-Path $MainPath "AndroidManifest.xml"

$GradlePath = Join-Path $AppPath "build.gradle"

$GradleKtsPath = Join-Path $AppPath "build.gradle.kts"


# ============================================================
# VALIDAR NOMBRE DE ACTIVITY
# ============================================================

# Formato válido:
#
# SplashActivity
# LoginActivity
# SettingsActivity
# UserProfileActivity
#
# No válido:
#
# splashactivity
# loginactivity
# splashActivity

if ($ActivityName -notmatch '^[A-Z][A-Za-z0-9]*Activity$') {

    Write-Host ""
    Write-Host "ERROR: El nombre de la Activity no es valido." -ForegroundColor Red
    Write-Host ""

    Write-Host "El nombre debe:"
    Write-Host "  - Comenzar con letra mayuscula"
    Write-Host "  - Terminar exactamente en Activity"
    Write-Host ""

    Write-Host "Ejemplos correctos:"
    Write-Host "    SplashActivity"
    Write-Host "    LoginActivity"
    Write-Host "    SettingsActivity"
    Write-Host "    UserProfileActivity"
    Write-Host ""

    exit 1
}


# ============================================================
# VALIDAR ESTRUCTURA DEL PROYECTO
# ============================================================

if (-not (Test-Path $AppPath)) {

    Write-Host ""
    Write-Host "ERROR: No se encontro la carpeta app." -ForegroundColor Red
    Write-Host ""
    Write-Host "Ruta esperada:"
    Write-Host "    $AppPath"
    Write-Host ""

    exit 1
}


if (-not (Test-Path $ManifestPath)) {

    Write-Host ""
    Write-Host "ERROR: No se encontro AndroidManifest.xml." -ForegroundColor Red
    Write-Host ""
    Write-Host "Ruta esperada:"
    Write-Host "    $ManifestPath"
    Write-Host ""

    exit 1
}


# ============================================================
# OBTENER NAMESPACE DESDE BUILD.GRADLE
# ============================================================

$Namespace = $null

if (Test-Path $GradlePath) {

    $GradleContent = Get-Content `
        -Path $GradlePath `
        -Raw `
        -Encoding UTF8

    # Busca:
    #
    # namespace 'com.example.app_demo'
    #
    # o:
    #
    # namespace "com.example.app_demo"

    $NamespaceMatch = [regex]::Match(
        $GradleContent,
        '(?m)^\s*namespace\s+["'']([^"'']+)["'']'
    )

    if ($NamespaceMatch.Success) {

        $Namespace = $NamespaceMatch.Groups[1].Value.Trim()
    }
}


# ============================================================
# OBTENER NAMESPACE DESDE BUILD.GRADLE.KTS
# ============================================================

if ([string]::IsNullOrWhiteSpace($Namespace) -and (Test-Path $GradleKtsPath)) {

    $GradleKtsContent = Get-Content `
        -Path $GradleKtsPath `
        -Raw `
        -Encoding UTF8

    # Busca:
    #
    # namespace = "com.example.app_demo"

    $NamespaceMatch = [regex]::Match(
        $GradleKtsContent,
        '(?m)^\s*namespace\s*=\s*["'']([^"'']+)["'']'
    )

    if ($NamespaceMatch.Success) {

        $Namespace = $NamespaceMatch.Groups[1].Value.Trim()
    }
}


# ============================================================
# FALLBACK: BUSCAR PACKAGE EN ANDROIDMANIFEST.XML
# ============================================================

if ([string]::IsNullOrWhiteSpace($Namespace)) {

    $ManifestContent = Get-Content `
        -Path $ManifestPath `
        -Raw `
        -Encoding UTF8

    $PackageMatch = [regex]::Match(
        $ManifestContent,
        'package\s*=\s*["'']([^"'']+)["'']'
    )

    if ($PackageMatch.Success) {

        $Namespace = $PackageMatch.Groups[1].Value.Trim()
    }
}


# ============================================================
# VALIDAR NAMESPACE
# ============================================================

if ([string]::IsNullOrWhiteSpace($Namespace)) {

    Write-Host ""
    Write-Host "ERROR: No se pudo detectar el namespace del proyecto." -ForegroundColor Red
    Write-Host ""

    Write-Host "Se revisaron:"
    Write-Host "    $GradlePath"
    Write-Host "    $GradleKtsPath"
    Write-Host "    $ManifestPath"
    Write-Host ""

    exit 1
}


# ============================================================
# MOSTRAR NAMESPACE DETECTADO
# ============================================================

Write-Host ""
Write-Host "Namespace detectado:" -ForegroundColor Cyan
Write-Host "    $Namespace"
Write-Host ""


# ============================================================
# DETERMINAR CARPETA JAVA DEL PACKAGE
# ============================================================

$PackagePath = $Namespace.Replace(".", "\")

$JavaPackagePath = Join-Path `
    $JavaPath `
    $PackagePath


# ============================================================
# CREAR DIRECTORIOS SI NO EXISTEN
# ============================================================

if (-not (Test-Path $JavaPackagePath)) {

    New-Item `
        -ItemType Directory `
        -Path $JavaPackagePath `
        -Force | Out-Null
}


if (-not (Test-Path $LayoutPath)) {

    New-Item `
        -ItemType Directory `
        -Path $LayoutPath `
        -Force | Out-Null
}


# ============================================================
# GENERAR NOMBRE DEL LAYOUT
# ============================================================

# Ejemplo:
#
# SplashActivity
#       ↓
# Splash
#       ↓
# splash
#       ↓
# activity_splash.xml

$LayoutName = $ActivityName -replace 'Activity$', ''

$LayoutName = $LayoutName.ToLower()

$LayoutFileName = "activity_$LayoutName.xml"


# ============================================================
# RUTAS DE ARCHIVOS
# ============================================================

$JavaFile = Join-Path `
    $JavaPackagePath `
    "$ActivityName.java"

$LayoutFile = Join-Path `
    $LayoutPath `
    $LayoutFileName


# ============================================================
# VERIFICAR SI YA EXISTEN
# ============================================================

if (Test-Path $JavaFile) {

    Write-Host ""
    Write-Host "ERROR: La Activity ya existe:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    $JavaFile"
    Write-Host ""

    exit 1
}


if (Test-Path $LayoutFile) {

    Write-Host ""
    Write-Host "ERROR: El layout ya existe:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    $LayoutFile"
    Write-Host ""

    exit 1
}


# ============================================================
# CREAR ARCHIVO JAVA
# UTF-8 SIN BOM
# ============================================================

$JavaContent = @"
package $Namespace;

import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;

public class $ActivityName extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_$LayoutName);
    }
}
"@


$Utf8NoBom = New-Object `
    System.Text.UTF8Encoding `
    $false


[System.IO.File]::WriteAllText(
    $JavaFile,
    $JavaContent,
    $Utf8NoBom
)


# ============================================================
# CREAR LAYOUT XML
# UTF-8 SIN BOM
# ============================================================

$XmlContent = @"
<?xml version="1.0" encoding="utf-8"?>

<LinearLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="16dp">

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="$ActivityName"
        android:textSize="24sp" />

</LinearLayout>
"@


[System.IO.File]::WriteAllText(
    $LayoutFile,
    $XmlContent,
    $Utf8NoBom
)


# ============================================================
# REGISTRAR ACTIVITY EN ANDROIDMANIFEST.XML
# ============================================================

$ManifestContent = Get-Content `
    -Path $ManifestPath `
    -Raw `
    -Encoding UTF8


# ============================================================
# VERIFICAR SI YA ESTA REGISTRADA
# ============================================================

$ActivityPattern = `
    'android:name\s*=\s*["'']\.' + `
    [regex]::Escape($ActivityName) + `
    '["'']'


if ($ManifestContent -notmatch $ActivityPattern) {

    $ActivityDeclaration = @"

        <activity
            android:name=".$ActivityName"
            android:exported="false" />
"@


    # ========================================================
    # BUSCAR CIERRE DE APPLICATION
    # ========================================================

    $ApplicationClose = '</application>'


    if ($ManifestContent.Contains($ApplicationClose)) {

        $ManifestContent = $ManifestContent.Replace(
            $ApplicationClose,
            "$ActivityDeclaration`r`n    </application>"
        )


        # ====================================================
        # GUARDAR MANIFEST UTF-8 SIN BOM
        # ====================================================

        [System.IO.File]::WriteAllText(
            $ManifestPath,
            $ManifestContent,
            $Utf8NoBom
        )

    }
    else {

        Write-Host ""
        Write-Host "ADVERTENCIA: No se encontro </application>." -ForegroundColor Yellow
        Write-Host ""

        Write-Host "La Activity Java y el layout fueron creados,"
        Write-Host "pero debes registrar manualmente la Activity."
        Write-Host ""
    }
}

# ============================================================
# RESULTADO
# ============================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host " ACTIVITY CREADA CORRECTAMENTE" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

Write-Host "Proyecto:"
Write-Host "    $ProjectRoot"

Write-Host ""
Write-Host "Nombre:"
Write-Host "    $ActivityName"

Write-Host ""
Write-Host "Namespace:"
Write-Host "    $Namespace"

Write-Host ""
Write-Host "Clase Java:"
Write-Host "    $JavaFile"

Write-Host ""
Write-Host "Layout XML:"
Write-Host "    $LayoutFile"

Write-Host ""
Write-Host "AndroidManifest:"
Write-Host "    Activity registrada"

Write-Host ""
Write-Host "============================================"
Write-Host " COMPILANDO PROYECTO ANDROID"
Write-Host "============================================"
Write-Host ""


# ============================================================
# COMPILAR PROYECTO ANDROID
# ============================================================

$GradlewPath = Join-Path $ProjectRoot "gradlew.bat"


# ============================================================
# VERIFICAR QUE EXISTE GRADLEW
# ============================================================

if (-not (Test-Path $GradlewPath)) {

    Write-Host ""
    Write-Host "ADVERTENCIA: No se encontro gradlew.bat." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Se crearon correctamente:"
    Write-Host "    - Activity Java"
    Write-Host "    - Layout XML"
    Write-Host "    - AndroidManifest.xml"
    Write-Host ""
    Write-Host "Pero no se pudo ejecutar la compilacion."
    Write-Host ""
    Write-Host "Ruta buscada:"
    Write-Host "    $GradlewPath"
    Write-Host ""

    exit 1
}


# ============================================================
# EJECUTAR GRADLE
#
# IMPORTANTE:
# Gradle debe ejecutarse desde la raiz del proyecto.
#
# Por eso usamos:
#
# Push-Location $ProjectRoot
#
# y luego:
#
# .\gradlew.bat :app:assembleDebug
# ============================================================

Push-Location $ProjectRoot

try {

    & $GradlewPath :app:assembleDebug

    $GradleExitCode = $LASTEXITCODE

}
finally {

    # Volver a la carpeta original
    Pop-Location
}


# ============================================================
# VERIFICAR RESULTADO DE LA COMPILACION
# ============================================================

if ($GradleExitCode -ne 0) {

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Red
    Write-Host " ERROR DE COMPILACION" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host ""

    Write-Host "La Activity y el layout fueron creados,"
    Write-Host "pero Gradle encontro errores durante la compilacion."
    Write-Host ""

    Write-Host "Codigo de salida:"
    Write-Host "    $GradleExitCode"

    Write-Host ""

    exit $GradleExitCode
}


# ============================================================
# COMPILACION EXITOSA
# ============================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host " COMPILACION EXITOSA" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

Write-Host "La nueva Activity fue creada y el proyecto"
Write-Host "Android compilo correctamente."

Write-Host ""

Write-Host "APK generado en:"
Write-Host "    $ProjectRoot\app\build\outputs\apk\debug\app-debug.apk"

Write-Host ""


# ============================================================
# RECARGAR PROYECTO EN VS CODE
# ============================================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " ACTUALIZANDO PROYECTO EN VS CODE"
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$CodeCommand = Get-Command code -ErrorAction SilentlyContinue

if ($null -ne $CodeCommand) {

    Write-Host "Actualizando workspace de VS Code..."

    try {

        & code --reuse-window $ProjectRoot

        Write-Host ""
        Write-Host "Workspace actualizado correctamente." -ForegroundColor Green

    }
    catch {

        Write-Host ""
        Write-Host "ADVERTENCIA: No se pudo actualizar VS Code." -ForegroundColor Yellow
        Write-Host $_.Exception.Message
    }

}
else {

    Write-Host ""
    Write-Host "ADVERTENCIA: No se encontro el comando 'code'." -ForegroundColor Yellow
    Write-Host ""

    Write-Host "El proyecto compilo correctamente,"
    Write-Host "pero VS Code no pudo ser actualizado automaticamente."
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host " PROCESO FINALIZADO" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
