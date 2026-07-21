@echo off
title Android App - Compila 

cd /d "%~dp0.."

echo.
echo ========================================
echo     COMPILANDO APLICACION ANDROID     
echo ========================================
echo.

call gradlew.bat :app:assembleDebug

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo       COMPILACION EXITOSA
    echo ========================================
) else (
    echo.
    echo ========================================
    echo       ERROR EN LA COMPILACION
    echo ========================================
)
