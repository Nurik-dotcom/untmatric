@echo off
REM run_tests.bat - запускает тесты UNTformatic на Windows
REM Использует Godot headless режим

setlocal enabledelayedexpansion

echo 🧪 Running UNTformatic Tests
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

REM Попробуйте найти Godot в PATH
where godot >nul 2>nul
if %errorlevel% equ 0 (
    set GODOT_PATH=godot
) else (
    REM Альтернативные пути
    if exist "C:\Program Files\Godot\godot.exe" (
        set GODOT_PATH=C:\Program Files\Godot\godot.exe
    ) else if exist "C:\Program Files (x86)\Godot\godot.exe" (
        set GODOT_PATH=C:\Program Files (x86)\Godot\godot.exe
    ) else (
        echo ✗ Godot не найден в PATH. Установите Godot или установите GODOT_PATH переменную.
        exit /b 1
    )
)

echo Project: %cd%
echo Godot: !GODOT_PATH!
echo Test Scene: res://tests/TestRunner.tscn
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

REM Запустить тесты в headless режиме
"!GODOT_PATH!" --headless --scene res://tests/TestRunner.tscn

set EXIT_CODE=%errorlevel%

echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo Test execution completed with exit code: !EXIT_CODE!
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

exit /b !EXIT_CODE!
