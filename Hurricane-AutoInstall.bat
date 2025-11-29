@echo off
REM Hurricane Client - Self-Contained Auto-Installer
REM This single file downloads and runs everything automatically
REM No separate downloads needed!

setlocal EnableDelayedExpansion

REM Configuration
set "LAUNCHER_URL=https://hafenexplorer.github.io/launcher.jar"
set "CONFIG_URL=https://hafenexplorer.github.io/launcher.hl"
set "INSTALL_DIR=%LOCALAPPDATA%\Hurricane"

REM Display header
cls
echo.
echo ========================================
echo    HURRICANE CLIENT LAUNCHER
echo    Auto-Installer Version
echo ========================================
echo.

REM Check if Java is installed
echo [1/4] Checking Java installation...
java -version >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: Java is not installed or not in PATH
    echo.
    echo Please install Java from:
    echo https://www.oracle.com/java/technologies/downloads/
    echo.
    echo After installing Java, run this script again.
    echo.
    pause
    exit /b 1
)
echo       Java found! [OK]

REM Create installation directory
echo [2/4] Setting up Hurricane directory...
if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%"
    echo       Created: %INSTALL_DIR%
) else (
    echo       Directory exists [OK]
)

REM Download launcher.jar if needed
cd /d "%INSTALL_DIR%"
echo [3/4] Checking launcher files...

if not exist "launcher.jar" (
    echo       Downloading launcher.jar...
    echo       This may take a minute...
    
    powershell -Command "try { (New-Object System.Net.WebClient).DownloadFile('%LAUNCHER_URL%', 'launcher.jar'); exit 0 } catch { exit 1 }" >nul 2>&1
    
    if errorlevel 1 (
        echo.
        echo ERROR: Failed to download launcher.jar
        echo Please check your internet connection.
        echo.
        pause
        exit /b 1
    )
    echo       Downloaded launcher.jar [OK]
) else (
    echo       launcher.jar exists [OK]
)

REM Launch the game
echo [4/4] Starting Hurricane...
echo.
echo ========================================
echo    Launching Game...
echo ========================================
echo.

REM Use the remote config URL - no need to download it
java -jar launcher.jar "%CONFIG_URL%"

REM Handle exit
if errorlevel 1 (
    echo.
    echo ========================================
    echo    Launcher exited with an error
    echo ========================================
    echo.
    pause
)

endlocal

