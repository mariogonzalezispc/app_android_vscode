@echo off
title Android App - Compila +  Upload

cd /d "%~dp0.."

echo.
echo ========================================
echo       COMPILANDO APLICACION ANDROID
echo ========================================
echo.

call gradlew.bat :app:assembleDebug

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo       ERROR EN LA COMPILACION
    echo ========================================
    pause
    exit /b 1
)

echo.
echo ========================================
echo       COMPILACION EXITOSA
echo ========================================
echo.

echo ========================================
echo       INSTALANDO EN EL TELEFONO
echo ========================================
echo.

call gradlew.bat :app:installDebug

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo       ERROR EN LA INSTALACION
    echo ========================================
    pause
    exit /b 1
)

echo.
echo ========================================
echo       INSTALACION EXITOSA
echo ========================================
echo.

echo ========================================
echo       ABRIENDO APLICACION
echo ========================================
echo.

"%ANDROID_HOME%\platform-tools\adb.exe" shell monkey -p com.example.app_demo 1


if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo       ERROR AL ABRIR LA APLICACION
    echo ========================================
    pause
    exit /b 1
)

echo.
echo ========================================
echo       APLICACION EJECUTANDOSE
echo ========================================
echo.