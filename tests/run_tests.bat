@echo off
REM run_tests.bat - runs UNTformatic tests on Windows.

setlocal

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "PROJECT_DIR=%%~fI"
set "TEST_SCENE=res://tests/TestRunner.tscn"

if "%GODOT_PATH%"=="" (
    where godot >nul 2>nul
    if %ERRORLEVEL% EQU 0 (
        set "GODOT_PATH=godot"
    ) else (
        if exist "C:\Program Files\Godot\godot.exe" (
            set "GODOT_PATH=C:\Program Files\Godot\godot.exe"
        ) else if exist "C:\Program Files (x86)\Godot\godot.exe" (
            set "GODOT_PATH=C:\Program Files (x86)\Godot\godot.exe"
        )
    )
)

if "%GODOT_PATH%"=="" (
    echo [ERROR] Godot executable not found. Set GODOT_PATH or add godot to PATH.
    exit /b 1
)

echo [INFO] Running UNTformatic tests
echo [INFO] Project: %PROJECT_DIR%
echo [INFO] Godot: %GODOT_PATH%
echo [INFO] Test scene: %TEST_SCENE%
echo.

pushd "%PROJECT_DIR%" >nul
"%GODOT_PATH%" --headless --path "%PROJECT_DIR%" --scene "%TEST_SCENE%"
set "EXIT_CODE=%ERRORLEVEL%"
popd >nul

echo [INFO] Test execution completed with exit code: %EXIT_CODE%

exit /b %EXIT_CODE%
