@echo off
title Android App - Upload

cd /d "%~dp0.."

echo.
echo ========================================
echo       INSTALANDO APK EN EL TELEFONO
echo ========================================
echo.

call gradlew.bat :app:installDebug

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo       INSTALACION EXITOSA
    echo ========================================
) else (
    echo.
    echo ========================================
    echo       ERROR EN LA INSTALACION
    echo ========================================
)

echo ========================================
echo       ABRIENDO APLICACION
echo ========================================
echo.

adb shell monkey -p com.example.app_demo 1

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
