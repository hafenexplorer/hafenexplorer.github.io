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
echo [1/5] Checking Java installation...
java -version >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: Java is not installed or not in PATH
    echo.
    echo Please install Java 11 or newer from:
    echo https://adoptium.net/temurin/releases/
    echo.
    echo After installing Java, run this script again.
    echo.
    pause
    exit /b 1
)

REM Check Java version (need Java 11+)
echo       Checking Java version...
for /f tokens^=2-5^ delims^=.-_^" %%j in ('java -version 2^>^&1') do (
    set "JAVA_MAJOR=%%j"
    goto :check_version
)

:check_version
if "%JAVA_MAJOR%" == "1" (
    REM Old version format like 1.8
    echo.
    echo ERROR: Java version is too old
    echo        You have: Java 8 or older
    echo        Required: Java 11 or newer
    echo.
    echo Please download Java 11 or newer from:
    echo https://adoptium.net/temurin/releases/
    echo.
    echo Recommended: Download "JRE" (smaller) or "JDK" 
    echo Choose: Windows x64 (MSI installer)
    echo.
    pause
    exit /b 1
)

if %JAVA_MAJOR% LSS 11 (
    echo.
    echo ERROR: Java version is too old  
    echo        You have: Java %JAVA_MAJOR%
    echo        Required: Java 11 or newer
    echo.
    echo Please download Java from:
    echo https://adoptium.net/temurin/releases/
    echo.
    pause
    exit /b 1
)

echo       Java %JAVA_MAJOR% found! [OK]

REM Create installation directory
echo [2/5] Setting up Hurricane directory...
if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%"
    echo       Created: %INSTALL_DIR%
) else (
    echo       Directory exists [OK]
)

REM Download launcher.jar if needed
cd /d "%INSTALL_DIR%"
echo [3/5] Checking launcher files...

if not exist "launcher.jar" (
    echo       Downloading launcher.jar...
    echo       This may take a minute...
    
    powershell -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('%LAUNCHER_URL%', 'launcher.jar'); exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }"
    
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

REM Verify launcher.jar was downloaded
echo [4/5] Verifying launcher...
if not exist "launcher.jar" (
    echo       ERROR: launcher.jar not found after download
    echo       Please check your internet connection and try again.
    pause
    exit /b 1
)

REM Get file size to verify it's not empty
for %%A in ("launcher.jar") do set SIZE=%%~zA
if %SIZE% LSS 1000 (
    echo       ERROR: launcher.jar file is too small or corrupt
    echo       Deleting and will re-download on next run
    del launcher.jar
    pause
    exit /b 1
)
echo       Launcher verified [OK]

REM Launch the game
echo [5/5] Starting Hurricane...
echo.
echo ========================================
echo    Launching Game...
echo ========================================
echo.
echo This may take a few minutes on first launch
echo as the game downloads required files...
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
    echo Common issues:
    echo   - Java version too old (need Java 11+)
    echo   - Missing game files (will download on first run)
    echo   - Internet connection problem
    echo.
    pause
)

endlocal
