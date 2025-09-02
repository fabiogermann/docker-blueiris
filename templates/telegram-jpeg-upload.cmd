@echo off
setlocal ENABLEDELAYEDEXPANSION

REM ====== CONFIG ======
set "SCRIPT_WINE_UNIX=/config/.wine/drive_c/BlueIris/Telegram-Upload/jpegupload.sh"
set "SCRIPT_WIN=C:\BlueIris\Telegram-Upload\jpegupload.sh"
REM =====================

REM --- 1) Detect Wine ---
reg query "HKCU\Software\Wine" >nul 2>&1
if %ERRORLEVEL%==0 (
    echo Detected Wine. Launching via Wine start /unix...
    start /unix "%SCRIPT_WINE_UNIX%"
    goto :EOF
)

REM --- 2) Detect WSL ---
where wsl.exe >nul 2>&1 || goto NOWSL

REM At least one distro?
for /f "delims=" %%D in ('wsl.exe -l -q 2^>nul') do (
    set "HAS_DISTRO=1"
    goto :HAVE_DISTRO
)
:HAVE_DISTRO
if not defined HAS_DISTRO goto NOWSL

REM Convert Windows path -> Linux path using wslpath (lowercase drive handled automatically)
for /f "usebackq delims=" %%P in (`wsl.exe wslpath -a -u "%SCRIPT_WIN%"`) do set "WSL_PATH=%%P"

echo Detected Windows with WSL. Running script inside WSL:
echo   !WSL_PATH!

REM Make executable and run
wsl.exe bash -lc "chmod +x \"!WSL_PATH!\" && \"!WSL_PATH!\""
goto :EOF

:NOWSL
echo ERROR: Not running under Wine, and WSL is not installed or no distro is registered. 1>&2
exit /b 1
