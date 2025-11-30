@echo off
REM Force window to stay open - add pause at start for debugging
echo Starting Neuro Toxin Auto-Installer...
echo.
timeout /t 2 >nul

setlocal EnableDelayedExpansion

REM Configuration
set "LAUNCHER_URL=https://hafenexplorer.github.io/launcher.jar"
set "CONFIG_URL=https://hafenexplorer.github.io/launcher.hl"
set "INSTALL_DIR=%LOCALAPPDATA%\Neuro-Toxin"

REM Display header
cls
echo.
echo ========================================
echo    NEURO TOXIN CLIENT AUTO-INSTALLER
echo ========================================
echo.

REM Check Java
echo [1/5] Checking Java...
Java -version 2>&1 | findstr /i "version"
if errorlevel 1 (
    echo.
    echo ERROR: Java not found
    echo Install from: https://adoptium.net/temurin/releases/
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)
echo Java found!
echo.

REM Check Java version
echo [2/5] Checking Java version...
for /f "tokens=3" %%v in ('Java -version 2^>^&1 ^| findstr /i "version"') do (
    set JAVA_VERSION=%%v
    goto :got_version
)

:got_version
set JAVA_VERSION=%JAVA_VERSION:"=%
echo Java version: %JAVA_VERSION%

REM Simple version check - just check if it's 1.8
echo %JAVA_VERSION% | findstr /i "1.8" >nul
if not errorlevel 1 (
    echo.
    echo ERROR: Java 8 detected - too old!
    echo Required: Java 11 or newer
    echo Download from: https://adoptium.net/temurin/releases/
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)
echo Version OK
echo.

REM Create directory (clean if exists)
echo [3/5] Setting up directory...
if exist "%INSTALL_DIR%" (
    echo Directory exists - cleaning old files...
    REM Remove old launcher.jar if it exists
    if exist "%INSTALL_DIR%\launcher.jar" (
        del "%INSTALL_DIR%\launcher.jar" 2>nul
        echo Removed old launcher.jar
    )
    REM Remove any other old files (optional - uncomment if you want to clean everything)
    REM del "%INSTALL_DIR%\*.*" /Q 2>nul
) else (
    mkdir "%INSTALL_DIR%"
    echo Created: %INSTALL_DIR%
)

cd /d "%INSTALL_DIR%"
echo.

REM Download launcher (always overwrite)
echo [4/5] Downloading/Updating launcher...
if exist "launcher.jar" (
    echo Existing launcher.jar found - will be replaced
    del "launcher.jar" 2>nul
)
echo Downloading launcher.jar...
echo Please wait...
echo.

powershell -Command "$ProgressPreference = 'SilentlyContinue'; try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('%LAUNCHER_URL%', 'launcher.jar'); Write-Host 'Download complete'; exit 0 } catch { Write-Host 'Error:' $_.Exception.Message; exit 1 }"

if errorlevel 1 (
    echo.
    echo ERROR: Download failed
    echo Check internet connection
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)
echo Downloaded successfully (overwritten if existed)
echo.

REM Copy res folder if needed
if exist "res" (
    echo Found local res folder
) else (
    echo Note: res folder should be downloaded by launcher
)
echo.

REM Launch
echo [5/5] Starting Neuro Toxin...
echo.
echo Launching game...
echo Window will stay open for debugging
echo.
echo Working directory: %CD%
echo.
echo ========================================
echo.

Java -jar launcher.jar "%CONFIG_URL%"
set EXIT_CODE=%errorlevel%

echo.
echo ========================================
echo Game exited with code: %EXIT_CODE%
echo.
if %EXIT_CODE% NEQ 0 (
    echo Something went wrong!
    echo Check error messages above
    echo.
)
echo Installation directory: %INSTALL_DIR%
echo.
echo Press any key to close...
pause >nul
exit /b %EXIT_CODE%


