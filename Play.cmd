@echo off
set "GODOT_EXE=D:\funny\Godot_latest_version\Godot.exe"
if not exist "%GODOT_EXE%" (
    echo Godot not found. Import project.godot using your Godot editor.
    pause
    exit /b 1
)
"%GODOT_EXE%" --path "%~dp0." --log-file "%~dp0docs\play.log"
