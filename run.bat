@echo off
rem Taskbar Inn launcher. Double-click to start the small window game.
rem ASCII only: a Japanese (UTF-8) batch breaks under cmd.exe (CP932).

set "GODOT=C:\Users\Tonami\Desktop\gamedev\engines\godot\4.6.3\godot.exe"

rem %~dp0 ends with a backslash; strip it so "path\" does not eat the quote.
set "PROJ=%~dp0"
if "%PROJ:~-1%"=="\" set "PROJ=%PROJ:~0,-1%"

rem Always rebuild the global class cache before launch.
rem Reason: the cache file can exist but be STALE (e.g. a newly added
rem class_name is missing). A stale cache makes "Could not find type ..."
rem errors that silently break parts of the UI. Importing every launch is
rem cheap for this tiny project and guarantees a fresh, complete cache.
echo Refreshing class cache...
"%GODOT%" --headless --path "%PROJ%" --import

echo Starting Taskbar Inn...
"%GODOT%" --path "%PROJ%"

if errorlevel 1 (
    echo.
    echo Launch failed. See the error above.
    pause
)
